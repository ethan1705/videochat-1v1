<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Chat Vidéo 1v1</title>
  <style>
    body { font-family: sans-serif; text-align: center; background: #111; color: white; }
    video { width: 45%; margin: 1rem; border: 2px solid white; }
    select, button { padding: 10px; margin: 10px; font-size: 16px; }
  </style>
</head>
<body>
  <h1>Chat Vidéo 1v1</h1>
  <label for="role">Choisis ton rôle :</label>
  <select id="role">
    <option value="femme">Femme</option>
    <option value="homme">Homme</option>
  </select>
  <button onclick="joinChat()">Rejoindre</button>

  <div id="videos" style="display: none;">
    <video id="localVideo" autoplay muted></video>
    <video id="remoteVideo" autoplay></video>
  </div>

  <script src="/socket.io/socket.io.js"></script>
  <script>
    const socket = io();
    let peerConnection;
    let localStream;
    const config = {
      iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
    };

    function joinChat() {
      const role = document.getElementById('role').value;
      document.querySelector('select').disabled = true;
      document.querySelector('button').disabled = true;
      document.getElementById('videos').style.display = 'block';

      navigator.mediaDevices.getUserMedia({ video: true, audio: true }).then(stream => {
        localStream = stream;
        document.getElementById('localVideo').srcObject = stream;
        socket.emit('join', role);
      });

      socket.on('offer', (offer) => {
        peerConnection = new RTCPeerConnection(config);
        peerConnection.setRemoteDescription(new RTCSessionDescription(offer));
        localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));
        peerConnection.ontrack = event => {
          document.getElementById('remoteVideo').srcObject = event.streams[0];
        };
        peerConnection.createAnswer().then(answer => {
          peerConnection.setLocalDescription(answer);
          socket.emit('answer', answer);
        });
      });

      socket.on('answer', answer => {
        peerConnection.setRemoteDescription(new RTCSessionDescription(answer));
      });

      socket.on('ready', () => {
        peerConnection = new RTCPeerConnection(config);
        localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));
        peerConnection.ontrack = event => {
          document.getElementById('remoteVideo').srcObject = event.streams[0];
        };
        peerConnection.onicecandidate = event => {
          if (event.candidate) {
            socket.emit('candidate', event.candidate);
          }
        };
        peerConnection.createOffer().then(offer => {
          peerConnection.setLocalDescription(offer);
          socket.emit('offer', offer);
        });
      });

      socket.on('candidate', candidate => {
        peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
      });
    }
  </script>
</body>
</html>