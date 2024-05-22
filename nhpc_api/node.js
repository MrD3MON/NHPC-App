const express = require('express');
const mysql = require('mysql');
const fs = require('fs');
const path = require('path');
const { Server } = require('http');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

// Create MySQL connection
const connection = mysql.createConnection({
  host: '127.0.0.1',
  user: 'root', // Your MySQL username
  password: '1234', // Your MySQL password
  database: 'nhpc' 
});

// Connect to MySQL
connection.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL database: ' + err.stack);
    return;
  }
  console.log('Connected to MySQL database as id ' + connection.threadId);
});

// API endpoint to fetch circular data
app.get('/api/circulars', (req, res) => {
  // Fetch data from the 'circular' table
  connection.query('SELECT Circular_Date, Circular_Title, Circular_Id, PDF_File, Attachments, Notification FROM circular', (error, results) => {
    if (error) {
      console.error('Error fetching circular data: ' + error.stack);
      res.status(500).send('Internal server error');
      return;
    }
    // Send the fetched data as JSON response
    res.json(results);
  });
});

// Add a new API endpoint to fetch Notification_File
app.get('/api/circulars/notification-file/:circularId', (req, res) => {
  const circularId = req.params.circularId;

  // Fetch Notification_File based on Circular_Id
  connection.query('SELECT Notification_File FROM circular WHERE Circular_Id = ?', [circularId], (error, results) => {
    if (error) {
      console.error('Error fetching Notification_File: ' + error.stack);
      res.status(500).send('Internal server error');
      return;
    }

    if (results.length === 0 || !results[0].Notification_File) {
      res.status(404).send('Notification file not found');
      return;
    }

    const notificationFile = results[0].Notification_File;
    // Assuming the notification files are stored in a specific directory
    const filePath = 'D:/NHPC_API/files/' + notificationFile + '.pdf';

    // Check if the notification file exists
    fs.access(filePath, fs.constants.F_OK, (err) => {
      if (err) {
        console.error('Error accessing notification file: ' + err);
        res.status(500).send('Internal server error');
        return;
      }

      // Send the notification file path
      //res.json({ url: filePath });
      res.download(filePath, notificationFile);
    });
  });
});

// API endpoint to fetch and serve PDF file based on Circular_Id
app.get('/api/circulars/pdf/:circularId', (req, res) => {
  const circularId = req.params.circularId;

  // Fetch PDF_File based on Circular_Id
  connection.query('SELECT PDF_File FROM circular WHERE Circular_Id = ?', [circularId], (error, results) => {
    if (error) {
      console.error('Error fetching PDF file: ' + error.stack);
      res.status(500).send('Internal server error');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('PDF file not found');
      return;
    }

    const pdfFileName = results[0].PDF_File;
    const pdfFilePath = 'D:/NHPC_API/files/' + pdfFileName + '.pdf'; // Replace with actual path to PDF files

    // Check if the PDF file exists
    fs.access(pdfFilePath, fs.constants.F_OK, (err) => {
      if (err) {
        console.error('Error accessing PDF file: ' + err);
        res.status(500).send('Internal server error');
        return;
      }

      // Serve the PDF file
        res.download(pdfFilePath, pdfFileName);
    });
  });
});

app.get('/api/circulars/attachments/:circularId/:index', (req, res) => {
  const circularId = req.params.circularId;
  const index = req.params.index;

  // Fetch Attachments column based on Circular_Id
  connection.query('SELECT Attachments FROM circular WHERE Circular_Id = ?', [circularId], (error, results) => {
    if (error) {
      console.error('Error fetching attachments: ' + error.stack);
      res.status(500).send('Internal server error');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Attachments not found');
      return;
    }

    const attachments = results[0].Attachments;
    const attachmentFileNames = attachments.split(',');
    
    if (index < 0 || index >= attachmentFileNames.length) {
      res.status(404).send('Attachment not found');
      return;
    }

    const fileName = attachmentFileNames[index];
    const extensions = ['.pdf', '.xls', '.doc', '.docx', '.html', '.odt', '.xlsx', '.ppt', '.pptx', '.txt'];
    let filePath;

    // Check for the existence of the file with different extensions
    extensions.some(extension => {
      const fullFilePath = 'D:/NHPC_API/files/' + fileName + extension;
      if (fs.existsSync(fullFilePath)) {
        filePath = fullFilePath;
        return true; // Stop searching if file with extension is found
      }
      return false; // Continue searching for next extension
    });

    if (filePath) {
      // Serve the attachment file
      res.download(filePath, fileName, err => {
        if (err) {
          console.error('Error sending file:', err);
          res.status(500).send('Internal server error');
        }
      });
    } else {
      //console.error('' + fileName);
      res.status(404).send('Attachment file not found');
    }
  });
});

app.get('/api/circulars/attachments/index/:circularId', (req, res) => {
  const circularId = req.params.circularId;

  // Fetch Attachments column based on Circular_Id
  connection.query('SELECT Attachments FROM circular WHERE Circular_Id = ?', [circularId], (error, results) => {
    if (error) {
      console.error('Error fetching attachments: ' + error.stack);
      res.status(500).send('Internal server error');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Attachments not found');
      return;
    }

    const attachments = results[0].Attachments;
    const attachmentFileNames = attachments.split(',');

    // Define a function to serve attachment files recursively
    function serveAttachment(index) {
      if (index >= attachmentFileNames.length) {
        // All files have been sent
        return;
      }

      const fileName = attachmentFileNames[index];
      const extensions = ['.pdf', '.xls', '.doc', '.docx', '.html', '.odt', '.xlsx', '.ppt', '.pptx', '.txt'];
      let filePath;

      // Check for the existence of the file with different extensions
      extensions.some(extension => {
        const fullFilePath = 'D:/NHPC_API/files/' + fileName + extension;
        if (fs.existsSync(fullFilePath)) {
          filePath = fullFilePath;
          return true; // Stop searching if file with extension is found
        }
        return false; // Continue searching for next extension
      });

      if (filePath) {
        // Serve the attachment file
        res.download(filePath, fileName, err => {
          if (err) {
            console.error('Error sending file:', err);
          } else {
            // Serve the next attachment file recursively
            serveAttachment(index + 1);
          }
        });
      } else {
        console.error('Attachment file not found: ' + fileName);
        // Serve the next attachment file recursively
        serveAttachment(index + 1);
      }
    }

    // Start serving attachment files recursively from index 0
    serveAttachment(0);
  });
});

app.get('/dropdown-options', (req, res) => {
  const query = 'SELECT loc_name FROM code'; // Query to select loc_name column from code table
  connection.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching options:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }
    const options = results.map((row) => row.loc_name); // Extract loc_name values from query results
    res.json(options); // Send the options as JSON response
  });
});

app.get('/hospital-data', (req, res) => {
  const locName = req.query.locName;
  const locIdQuery = 'SELECT Loc_id FROM code WHERE loc_name = ?';
  connection.query(locIdQuery, [locName], (err, locResults) => {
    if (err) {
      console.error('Error fetching loc_id:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }
    if (locResults.length === 0) {
      res.status(404).json({ error: 'Location not found' });
      return;
    }
    const locId = locResults[0].Loc_id;
    const directoryQuery = `
      SELECT Hosp_name, hosp_add, valid_from, VALID_UPTO, RegValidUptoDt, Rem, Approval_Order, Tariff, Facilitation
      FROM directory
      WHERE LOC_CODE = ?
    `;
    connection.query(directoryQuery, [locId], (err, dirResults) => {
      if (err) {
        console.error('Error fetching hospital data:', err);
        res.status(500).json({ error: 'Internal server error' });
        return;
      }
      res.json(dirResults);
    });
  });
});

// Add a route for downloading PDF files
app.get('/download-pdf', (req, res) => {
  const fileName = req.query.fileName;
  const filePath = 'D:/NHPC_API/directory_files/' + fileName + '.pdf'; // Adjust the directory as per your setup
  const fileExists = fs.existsSync(filePath);
  if (fileExists) {
    // Set response headers for PDF file
    res.setHeader('Content-disposition', `attachment; filename=${fileName}`);
    res.setHeader('Content-type', 'application/pdf');
    // Pipe the PDF file to response
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.status(404).send('File not found');
  }
});

/*app.get('/download-pdf', (req, res) => {
  const fileName = req.query.fileName;
  const directoryPath = 'D:/NHPC_API/directory_files/';
  const allowedExtensions = ['.pdf', '.xls', '.doc', '.docx', '.html', '.odt', '.xlsx', '.ppt', '.pptx', '.txt'];

  let fileFound = false;
  let filePath = '';
  let fileExtension = '';

  // Search for the file with any of the allowed extensions
  for (const ext of allowedExtensions) {
    filePath = directoryPath + fileName + ext;
    if (fs.existsSync(filePath)) {
      fileFound = true;
      fileExtension = ext;
      break;
    }
  }

  if (fileFound) {
    // Set response headers for the file
    res.setHeader('Content-disposition', `attachment; filename=${fileName}${fileExtension}`);
    res.setHeader('Content-type', mimeType(fileExtension)); // Set the correct MIME type based on the file extension

    // Pipe the file to the response
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.status(404).send('File not found');
  }
});

// Function to get the MIME type based on the file extension
function mimeType(extension) {
  const mimeTypes = {
    '.pdf': 'application/pdf',
    '.xls': 'application/vnd.ms-excel',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.html': 'text/html',
    '.odt': 'application/vnd.oasis.opendocument.text',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.ppt': 'application/vnd.ms-powerpoint',
    '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    '.txt': 'text/plain'
  };
  return mimeTypes[extension] || 'application/octet-stream';
}*/

// Check username API
app.post('/check-username', (req, res) => {
  const { username } = req.body;
  const query = 'SELECT Username FROM employee WHERE Username = ?';
  connection.query(query, [username], (err, results) => {
    if (err) {
      return res.status(500).send({ error: err.message });
    }
    if (results.length > 0) {
      // Username already exists
      res.status(409).send({ message: 'Username already exists' });
    } else {
      // Username is available
      res.send({ message: 'Username is available' });
    }
  });
});

// Sign-up API
app.post('/signup', (req, res) => {
  const { name, designation, username, password } = req.body;
  const employeeId = Math.floor(Math.random() * 1000); // Generate a random small number for Employee_Id

  const query = 'INSERT INTO employee (Name, Designation, Username, Password) VALUES (?, ?, ?, ?)';
  connection.query(query, [name, designation, username, password], (err, results) => {
    if (err) {
      return res.status(500).send({ error: err.message });
    }
    res.send({ message: 'Sign up successful', employeeId });
  });
});

// Login API
app.post('/login', (req, res) => {
    const { username, password } = req.body;
  
    const query = 'SELECT Name, Designation FROM employee WHERE Username = ? AND Password = ?';
    connection.query(query, [username, password], (err, results) => {
      if (err) {
        return res.status(500).send({ error: err.message });
      }
      if (results.length > 0) {
        // Login successful, send user details
        const user = results[0];
        res.send({ employeeId: user.Employee_Id, name: user.Name, designation: user.Designation });
      } else {
        // Login failed
        res.status(401).send({ message: 'Invalid username or password' });
      }
    });
  });

// Start the server
app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);

});