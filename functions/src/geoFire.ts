import * as firebase from 'firebase/app';
import 'firebase/firestore';
import { GeoCollectionReference, GeoFirestore, GeoQuery, GeoQuerySnapshot } from 'geofirestore';


firebase.initializeApp({
  apiKey: 'AIzaSyB9qzW3Mx8LMuXxP64KUFhm1pJjwHQIvBc',
	databaseURL: 'https://xfeed-497fe.firebaseio.com',
	projectId:'xfeed-497fe'
});

// Create a Firestore reference
const firestore = firebase.firestore();

// Create a GeoFirestore reference
export const geofirestore: GeoFirestore = new GeoFirestore(firestore);

