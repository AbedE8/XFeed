import * as admin from 'firebase-admin';
import { GeoPoint, CollectionReference, Timestamp } from '@google-cloud/firestore';
import { googleMapsClient } from "./clientsAPI"
import { DBController } from "./DBApi"

const BUILDING_NUMBER = 0
const STREET = 1
const CITY = 2
const DISTRICT = 3
const COUNTRY = 4

const RES_OK = 200
const RES_ERR = 404

export const uploadPostModule = function(req, res) {
	const uid = String(req.body.uid);
	const categories = req.body.category;
	const description = req.body.description;
	const feature_name = req.body.feature_name;
	const img_url = req.body.img_url;
	const latlng = {lat: req.body.lat, lng: req.body.lng};
	const timeStamp = new Date(req.body.timestamp);

	async function execUploadPost() {
		let status = RES_OK;
		let address = await parseAddressByLocation(latlng);
		let citiesDB = await admin.firestore().collection("cities").where("name", "==", address.address_components[CITY].long_name);
		await citiesDB.get().then(async function(querySnapshot){
													let newPostRef;
													let newLocationRef;

													/* in the frontened it will take care that user can upload post only after a fixed period of time .*/
													newPostRef = await insertNewPost(uid, categories, description, feature_name, img_url, timeStamp);
													if (newPostRef == null){
														status = RES_ERR;
													}

													if (querySnapshot.size == 1){
														// city exist.
														let locationName = address.address_components[STREET].long_name + " " + address.address_components[BUILDING_NUMBER].long_name;
														let cityDB = await querySnapshot.docs[0].data();

														let ret = await isLocationInCity(cityDB.locations, locationName);
														if (ret.res) {
															// location exist - insert the post to the location.
															await cityDB.locations[ret.positionOnArray].update({
																posts: admin.firestore.FieldValue.arrayUnion(newPostRef)
															});
														}	else {
															// location not exist - insert the new location and add it to city locations.
															newLocationRef = await insertNewLocation(address, [newPostRef]);
															if (newLocationRef == null){
																status = RES_ERR;
															}
													
															await querySnapshot.docs[0].ref.update({
																locations: admin.firestore.FieldValue.arrayUnion(newLocationRef)
															});
														}	
													} else if (querySnapshot.size == 0){
														// city not exist - first uploade in the current city.
														newLocationRef = await insertNewLocation(address, [newPostRef]);
														if (newLocationRef == null){
															status = RES_ERR;
														}
														/*TODO: set the new location ref as a map*/
														if (await insertNewCity(address.address_components, [newLocationRef]) == null){
															status = RES_ERR;
														}
													} else {
														/* TODO: handle to delete the post that allready inserted.*/
														console.log(querySnapshot.size);
														status = RES_ERR;
													}
													res.status(status).send();
										}).catch((err) => {
												console.log(err);
												res.status(RES_ERR).send();
											});
	}

	async function test(){
		console.log("test");
	}
	
	execUploadPost().then().catch();
	//test().then().catch();
}

async function parseAddressByLocation(latlng){
	/* TODO: first, search in the DB if we allready have this [lng,lat], if not then call google API. */
	return await googleMapsClient.reverseGeocode({latlng: latlng}).asPromise()
  .then((response) => {
    return response.json.results[0];
  })
  .catch((err) => {
    console.log(err);
  });
}

async function insertNewPost(uid, categories, description, feature_name, img_url, timeStamp){
			return await admin.firestore().collection("users").doc(uid).get()
			.then( async userRef => {
				let newPost = {
					category: categories,
					publisher: uid,
					description: description,
					feature_name: feature_name,
					img_url: img_url,
					timeStamp: timeStamp,
					comments: [],
					likes: [],
					referred_users: [],
					distribution_left: userRef.data().post_distribution
				};

				return await DBController.insertDocumentToCollection('posts', newPost, "new post published.");
			});	
}

async function insertNewCity(address_components, locations: any[]){
	let newCity = {
		name: address_components[CITY].long_name,
		locations: locations
	}

	return await DBController.insertDocumentToCollection('cities', newCity, "city " + newCity.name + " was added");
}

async function insertNewLocation(address, post){
	let newLocation = {
		name: address.address_components[STREET].long_name + " " + address.address_components[BUILDING_NUMBER].long_name ,
		point: address.geometry.location,
		posts: post
	}

	return await DBController.insertDocumentToCollection('locations', newLocation, "location " + newLocation.name + " was added");
}

async function isLocationInCity(cityLocationsDB, locationName){
	let ret = { res: false,
		positionOnArray: -1 };

	for(let i = 0; i < cityLocationsDB.length && !ret.res; i++) {
		await cityLocationsDB[i].get().then(location => {
			if (locationName != null && location.data().name == locationName){
				ret.positionOnArray = i;
				ret.res = true;
			}
		}).catch((err) => {
			console.log(err);
			ret.res = false;
		});
	}
	
	return ret;
}

