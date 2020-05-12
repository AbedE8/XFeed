import { DBController } from "./DBApi"
import { GeoCollectionReference, GeoQuery, GeoQuerySnapshot } from 'geofirestore';
import { geofirestore } from "./geoFire"
import * as moment from 'moment';
import * as admin from 'firebase-admin';


const NUM_OF_POST_IN_CHUNK = 1;
const PRIOD_TIME_OF_LOCATION_POSTS = 60 //by minutes

const geocollection: GeoCollectionReference = geofirestore.collection('geoLocation');
let user_id;

export const getLocationFeedModule = function(req, res) {
  const reqFeatureName = String(req.query.feature_name);

  async function getLocationFeed() {
    await getLocationFeedExec(reqFeatureName).then(listOfPosts => {
      let result = {'num_of_posts':NUM_OF_POST_IN_CHUNK, 'posts': listOfPosts};
      console.log(JSON.stringify(result));
      res.send(JSON.stringify(result));
    }).catch(err => {
      res.status(404).send(err);
      });
  }
  
  getLocationFeed().then().catch();

  async function getLocationFeedExec(featureName){
    let GeoLocationDB = await admin.firestore().collection("geoLocation").where("d.name", "==", featureName);
  
    return await GeoLocationDB.get().then(async function(locationSnapshot){
      if (locationSnapshot.size == 1){
        let locationPosts =  locationSnapshot.docs[0].data().d.posts;
        return await createFeedWithFirstChunkOfPosts(locationPosts.sort(sortByPublishedTime), NUM_OF_POST_IN_CHUNK);
        } else {
        throw new Error("num of locations with name " + featureName + "is " + locationSnapshot.size);
      }
    });
  }
}

/*
user_id -         user DB id
userPostPref - contain all user preferences for posts:
  -categories -  list of strings of the required categories (Food, NightLife, Activities, Culture, Outdoors, Shopping, Info)
  -gender -      "Male, Female" - the gender of the publisher of post that user want to see.
  -minAge -      posts that there publisher age is not larger
  -maxAge -      posts that there publisher age is not smaller
  -location -    (geopoint)contain the latitude and longitude of the location the user want to get post by.
  -radius -      the distance from the location to get posts by km.

  return - array [{NUM_OF_POST_IN_CHUNK}, {posts_with_data, posts id}]. the array is sorted by published time with consideration
           on the user post_preferences, posts_with_data size is NUM_OF_POST_IN_CHUNK.
*/
export const getFeedModule = function(req, res) {
  user_id = String(req.query.uid);

  async function compileFeedPost() {
    await getAllPostsByUserPref(user_id).then(listOfPosts => {
      let feed = [].concat.apply([], listOfPosts); // flattens list.
      let result = {'num_of_posts':NUM_OF_POST_IN_CHUNK, 'posts': feed};
      console.log(JSON.stringify(result));
      res.status(200).send(JSON.stringify(result));
    }).catch(err => {
      console.log(err);
      res.status(404).send(err);
      });
  }
  
  compileFeedPost().then().catch();

  async function getAllPostsByUserPref(uid) {
    //IMPORTENT!!!! user uid == user post preferences uid
    let userPostPref = (await DBController.getDocByUid(uid, "post_preferences")).data();
    let promises = (await getlocationsWithinRadius(userPostPref.location, userPostPref.radius)).map(async location => {
      let locationPosts = location.data().posts;
      return getPostFromLocation(locationPosts, userPostPref);
    });
  
    return await Promise.all(promises).then(async postArr => {
      return await createFeedWithFirstChunkOfPosts(postArr.sort(sortByPublishedTime), NUM_OF_POST_IN_CHUNK);
    }).catch(err => {
      console.log(err);
      throw new Error(err);
    });
  }
}

async function createFeedWithFirstChunkOfPosts(postArr, I_numOfPostsWithData){
  let numOfPostsWithData = I_numOfPostsWithData

  for (let i = 0; i < postArr.length; i++) {
    if (numOfPostsWithData){
      numOfPostsWithData--
      let post = await DBController.getDocByUid(postArr[i].id, "posts");
      postArr[i] = post.data();
      //increse view on post.
    } else if (postArr[i] != null){
      postArr[i] = {'post_id':postArr[i].id};
    } else {
      postArr.splice(i,1)
    }
  }

  return postArr
}

function sortByPublishedTime(postA, postB){
  if (postA == null && postB == null){
    return 0;
  } else if(postA == null) {
    return 1;
  } else if(postB == null) {
    return -1;
  } else {
    if (postA.timeStamp < postB.timeStamp){
      return -1
    };
    return 1;
  }
}

async function isPostMeetsThePreferences(userPostPref, post){
  let res = false;
  return await DBController.getDocByUid(post.publisher, "users").then( publisherRef => {
    let publisher = publisherRef.data(); 
    let publisherAge = moment().diff(moment(publisher.birthday, "MM/DD/YYYY"), 'years', false);
    
    if (userPostPref.Categories.some(r => post.category.includes(r)) &&
        userPostPref.gender.includes(publisher.gender) &&
        publisherAge <= userPostPref.maxAge &&
        publisherAge >= userPostPref.minAge &&
        post.publisher != user_id &&
        post.distribution > post.views){
      res = true;
    }
  
    return res;
  });
}

async function getlocationsWithinRadius(location, radius){ 
  const query: GeoQuery = geocollection.near({ center: location, radius: radius});
  return query.get().then((value: GeoQuerySnapshot) => {
    return value.docs;
  });
}

/*
locationPosts - sort array with all posts, the newest post set on last index.
*/
async function getPostFromLocation(locationPosts, userPostPref){
  let promises;
  let numOfPotentialPostsToRet = numOfPostOverPeriodTime(locationPosts, PRIOD_TIME_OF_LOCATION_POSTS);
  
  promises = await getPotentialPostsFromThePeriodTime(locationPosts, userPostPref, numOfPotentialPostsToRet);
  let res =  await Promise.all(promises).then(async potentialPostToRetArr => { return postLottery(potentialPostToRetArr)});
  
  return res;
}

/* postsArr - sort array with all posts, the newest post set on last index*/
function numOfPostOverPeriodTime(postsArr, priodTime){
  let numOfPostWhitinPariod = 0;
  let lastPostPublishedTime = moment(postsArr[postsArr.length -1].timeStamp.toDate());
  
  for(let i = postsArr.length -1; i >= 0 ; i--){
    let diffMinutes = lastPostPublishedTime.diff(moment(postsArr[i].timeStamp.toDate()), "minutes");

    if (-diffMinutes <= priodTime && diffMinutes <= 0){
      numOfPostWhitinPariod++;
    } else {
      break;
    }
  }

  return numOfPostWhitinPariod;
}

function postLottery(postArr){
  let numOfTickets = 0;
  let i;

  postArr.forEach(post => {
    if(post != null){
      numOfTickets += post.data().distribution - post.data().views;
    }
  });

  if (numOfTickets == 0){
    console.log("no post to lottery.");
    return null
  }
  let winnerNumber = Math.floor((Math.random() * Math.floor(numOfTickets)));
  
  for(i = postArr.length - 1; i >= 0 && winnerNumber > 0; i--){
    winnerNumber -= postArr[i].data().distribution - postArr[i].data().views
  }

  return postArr[i + 1];
}

async function getPotentialPostsFromThePeriodTime(locationPosts, userPostPref, i_numOfPotentialPostsToRet)
{
  let retPosts = [];
  let numOfPotentialPostsToRet = i_numOfPotentialPostsToRet;

  for(let i = locationPosts.length - 1; numOfPotentialPostsToRet > 0; i--){
    numOfPotentialPostsToRet--;
    await DBController.getDocByUid(locationPosts[i].id, "posts").then(async postRef => {
      await isPostMeetsThePreferences(userPostPref, postRef.data()).then(async res => {
        if (res){
          retPosts.push(postRef);
        }
      })
    });
  }
  return retPosts;
}