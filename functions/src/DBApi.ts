import * as admin from 'firebase-admin';

export const DBController = {
	insertDocumentToCollection: insertDocumentToCollection,
	getDocByUid: getDocByUid,
	incrementDocField: incrementDocField
}

async function insertDocumentToCollection(collectionName, documentToAdd, msg){
	return await admin.firestore().collection(collectionName).add(documentToAdd)
	.then(ref => {
		console.log(msg);
		return ref;})
	.catch((err) => {
		console.log(err);
		return null;
	});
}

async function getDocByUid(uid, collectionName) {
	return await admin.firestore().collection(collectionName).doc(uid).get();
}

function incrementDocField(collectionName, docId, field, amount){
	const increment = admin.firestore.FieldValue.increment(amount);
	let obj = {};
	obj[field] = increment;
	admin.firestore().collection(collectionName).doc(docId).update(obj).then().catch(err => {console.log(err);});
}
