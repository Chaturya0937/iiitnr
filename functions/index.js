const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();
sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendDueDateReminder = functions.pubsub
    .schedule("every 15 minutes")
    .onRun(async (context) => {
      const now = admin.firestore.Timestamp.now();
      const oneHourLaterDate = new Date(Date.now() + 60 * 60 * 1000);
      const oneHourLater = admin.firestore.Timestamp.fromDate(oneHourLaterDate);

      const snapshot = await admin.firestore().collection("batchid")
          .where("duedate", ">=", now)
          .where("duedate", "<=", oneHourLater)
          .get();

      snapshot.forEach((doc) => {
        const data = doc.data();
        const email = data.studentEmail;
        const dueDateFormatted = data.duedate.toDate().toLocaleString();

        if (email) {
          const msg = {
            to: email,
            from: "noreply@iiitnr-8209c.firebaseapp.com",
            subject: "Batch Due Date Reminder",
            text: `Hello, your batch is due at ${dueDateFormatted}.
                Please take the necessary actions.`,
          };
          sgMail.send(msg)
              .then(() => {
                console.log("Email sent to:", email);
              })
              .catch((error) => {
                console.error("Error sending email:", error);
              });
        }
      });

      return null;
    });
