import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';


export const getFeedModule = function(req, res) {
    const uid = String(req.query.uid);
    const categories = req.query.category;

    async function compileFeedPost() {
      const following = await getFollowing(uid, res) as any;
  
      let listOfPosts = await getAllPosts(following, uid, categories, res);
  
      listOfPosts = [].concat.apply([], listOfPosts); // flattens list
  
      res.send(listOfPosts);
    }
    
    compileFeedPost().then().catch();
}
  
async function getAllPosts(following, uid, categories, res) {
    const listOfPosts = [];
  
    for (const user in following){
        listOfPosts.push( await getUserPosts(following[user], categories, res));
    }

    // add the current user's posts to the feed so that your own posts appear in your feed
    listOfPosts.push( await getUserPosts(uid, categories, res));
    
    return listOfPosts; 
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
