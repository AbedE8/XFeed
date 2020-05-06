import * as admin from 'firebase-admin';
import * as firebase from 'firebase/app';
import { DBController } from "./DBApi"
import { geofirestore } from "./geoFire"
import { GeoCollectionReference } from 'geofirestore';

//TODO: set this in a file with all the globals.
const RES_OK = 200
const RES_ERR = 404

// Create a GeoCollection reference
const geocollection: GeoCollectionReference = geofirestore.collection('geoLocation');

export const uploadPostModule = function(req, res) {
	let uid = String(req.body.uid);
	let categories = req.body.category;
	let description = req.body.description;
	let feature_name = req.body.feature_name;
	let img_url = req.body.img_url;
	let latlng = {lat: Number(req.body.lat), lng: Number(req.body.lng)};
	let timeStamp = new Date(req.body.timestamp);

	async function execUploadPost() {
		let GeoLocationDB = await admin.firestore().collection("geoLocation").where("d.name", "==", feature_name);
	
		await GeoLocationDB.get().then(async function(querySnapshot){
			await insertNewPost(uid, categories, description, img_url, timeStamp, feature_name).then(async function(newPostRef){
				if (querySnapshot.size == 1){
					// location exist. add the new post to the location.
					await querySnapshot.docs[0].ref.set({d:{posts: admin.firestore.FieldValue.arrayUnion(newPostRef.id)}},{merge:true});
				} else if (querySnapshot.size == 0){
					// need to add new location with the new post.
					await geocollection.add({
							name: feature_name,
							coordinates: new firebase.firestore.GeoPoint(latlng.lat, latlng.lng),
							posts: [newPostRef.id]
					});
				} else {
					console.log("error - num of " + feature_name + " location is:" + querySnapshot.size);
				}
				res.status(RES_OK).send();
			})
		}).catch(err => {
			res.status(RES_ERR).send();
			console.log(err);
		});
	}

	async function insertNewPost(i_uid, i_categories, i_description, i_img_url, i_timeStamp, i_feature_name){
		return await admin.firestore().collection("users").doc(i_uid).get()
		.then( async userRef => {
			let newPost = {
				category: i_categories,
				publisher: i_uid,
				description: i_description,
				img_url: i_img_url,
				timeStamp: i_timeStamp,
				comments: [],
				likes: [],
				referred_users: [],
				distribution_left: userRef.data().post_distribution,
				feature_name: i_feature_name
			};
	
			return await DBController.insertDocumentToCollection('posts', newPost, "new post published.");
		});	
	}

	execUploadPost().then().catch();
}