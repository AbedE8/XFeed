import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as geolib from 'geolib';
import { GeoPoint, CollectionReference } from '@google-cloud/firestore';


export const getFeedModule = function(req, res) {
    const uid = String(req.query.uid);
    const categories = req.query.category;
    let location = new GeoPoint(Number(req.query.latitude), Number(req.query.longitude));
    let distance = req.query.distance;
    let gender = req.query.gender;

    async function compileFeedPost() {
      let listOfPosts = await getAllPosts(uid, categories, location, distance, gender, res);
      listOfPosts = [].concat.apply([], listOfPosts); // flattens list
      res.send(listOfPosts);
    }
    
    compileFeedPost().then().catch();
}

/*
uid -         user id from the DB
categories -  list of strings of the required categories (food, nightLife, activities, culture, outdoors, shopping, info)
location -    (geopoint)contain the latitude and longitude of the location the user want to get post by.
radius -      the distance from the location to get posts.
gender -      "male, female" - the gender of the publisher of post that user want to see..
*/
async function getAllPosts(uid, categories, location, radius, gender, res) {
    let postByLocation = [];
    let postByCategory = [];
    let postByGender = [];
    let allPostsFromDB;

    //TODO: do it more mempry wiesly.
    allPostsFromDB = await admin.firestore().collection("posts");
    postByLocation = await getPostByLocation(allPostsFromDB, location, radius);
    postByCategory = await getPostByCategory(postByLocation, categories);
    postByGender = await getPostByGender(postByCategory, gender);
    
    return postByGender; 
}

/* return all the post from the wanted gender.*/
async function getPostByGender(posts_input:any[], gender){
  const tmp = gender.slice(1,gender.length-1);
  const selected_gender = tmp.split(', ');
  const posts = [];

  console.log(selected_gender.length);
  if (selected_gender.length == 2) {
      return posts_input;
  }

  for(let i = 0; i < posts_input.length; i++){
    let snap = await posts_input[i].publisher.get();
    if (selected_gender[0] == snap.data().gender){
      posts.push(posts_input[i]);
    }
  }
  
  return posts;
}

/* return all the post with location insude the area of the location and radius.*/
function getPostByLocation(posts_input: CollectionReference, location, radius){
  return posts_input.get()
  .then(function(querySnapshot) {
    const post2ret = [];
    
    querySnapshot.forEach(post => {
      let post_data = post.data();
      //console.log("post location: la:" + post_data.location.latitude + " lo:" + post_data.location.longitude + " location: la:" + location.latitude + " lo:" + location.longitude + " r:" + radius);
      if (geolib.isPointWithinRadius({latitude: post_data.location.latitude, longitude: post_data.location.longitude},
                                      {latitude: location.latitude, longitude:location.longitude}, radius) == true) {
          post2ret.push(post_data);
      }
    })

    return post2ret;
  })
}

/* return all the post with the relevant categories.*/
function getPostByCategory(posts_input: any[], categories){
  const tmp = categories.slice(1,categories.length-1);
  const selected_categories = tmp.split(', ');
  const posts = [];

  posts_input.forEach(post => {
    if (selected_categories.includes(post.category)){
      posts.push(post);
    }
  })

  return posts
}
  













function getUserPosts(userId, categories, res){
    let posts;

    if(categories) {
      const tmp = categories.slice(1,categories.length-1);
      const all_categories = tmp.split(', ');
      posts = admin.firestore().collection("insta_posts").where("ownerId", "==", userId)
      .where("activity",'in',all_categories)
      .orderBy("timestamp","desc");
  
    }
    else{
      posts = admin.firestore().collection("insta_posts").where("ownerId", "==", userId).orderBy("timestamp","desc")    
    }
    
    return posts.get()
    .then(function(querySnapshot) {
        const listOfPosts = [];
  
        querySnapshot.forEach(function(doc) {
            listOfPosts.push(doc.data());
        });
  
        return listOfPosts;
    })
  }
  
function getFollowing(uid, res){
    const doc = admin.firestore().doc(`insta_users/${uid}`)
    return doc.get().then(snapshot => {
      const followings = snapshot.data().following;
      
      const following_list = [];
  
      for (const following in followings) {
        if (followings[following] === true){
          following_list.push(following);
        }
      }
      return following_list; 
  }).catch(error => {
      res.status(500).send(error)
    })
}