import * as admin from 'firebase-admin';

export const DBController = {
	insertDocumentToCollection: insertDocumentToCollection
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
