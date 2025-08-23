const express = require('express');
const admin = require('firebase-admin');

// Initialize Admin SDK with your service account JSON
admin.initializeApp({
  credential: admin.credential.cert(require('./service-account.json')),
});

const app = express();
app.use(express.json());

app.post('/send', async (req, res) => {
  const { title, body, topic = 'all' } = req.body;
  try {
    const message = { notification: { title, body }, topic };
    const response = await admin.messaging().send(message);
    res.json({ success: true, response });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Notification service listening on ${port}`));
