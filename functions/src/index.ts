import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { notificationHandlerModule } from "./notificationHandler"
import { getFeedModule } from "./getFeed"
var serviceAccount = require('../xfeed-497fe-firebase-adminsdk-wjgq3-df2a207afc.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://xfeed-497fe.firebaseio.com'
});

/*export const notificationHandler = functions.firestore.document("/insta_a_feed/{userId}/items/{activityFeedItem}")
    .onCreate(async (snapshot, context) => {
       await notificationHandlerModule(snapshot, context);
    });*/

export const getFeed = functions.https.onRequest((req, res) => {
  getFeedModule(req, res);
})

