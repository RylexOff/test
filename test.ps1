$port = 55000

# Récupérer l'adresse IP publique
$publicIPResponse = Invoke-RestMethod -Uri "https://api.ipify.org?format=json"
$publicIP = $publicIPResponse.ip

$siteContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Mon site avec une webcam en direct</title>
    <style>
        body, html {
            height: 100%;
            margin: 0;
            background-color: #444654;
            overflow: hidden;
        }

        #video-container {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100%;
            overflow: hidden;
        }

        #live-video {
            width: 100%;
            height: 100%;
            object-fit: contain;
            transition: all 0.3s ease;
        }

        #stretch-button {
            position: absolute;
            top: 10px;
            left: 10px;
            z-index: 1;
            width: 40px;
            height: 40px;
            background-color: transparent;
            border: none;
            cursor: pointer;
        }

        #stretch-button::before {
            content: "";
            display: block;
            width: 20px;
            height: 20px;
            border: 4px solid #fff;
            border-radius: 50%;
            position: relative;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
        }

        #download-button {
            position: absolute;
            bottom: 10px;
            left: 10px;
            width: 40px;
            height: 40px;
            background-color: transparent;
            border: none;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
        }

        #download-button::before {
            content: "";
            display: block;
            width: 0;
            height: 0;
            border-top: 15px solid transparent;
            border-bottom: 15px solid transparent;
            border-left: 20px solid #fff;
            transition: all 0.3s ease;
            transform: rotate(90deg);
        }

        #download-button.active::before {
            transform: rotate(270deg);
        }
    </style>
</head>
<body>
    <div id="video-container">
        <video id="live-video" autoplay></video>
        <button id="stretch-button"></button>
        <button id="download-button"></button>
    </div>

    <script>
        // Accès à la webcam
        navigator.mediaDevices.getUserMedia({ video: true })
            .then(function(stream) {
                var videoElement = document.getElementById('live-video');
                videoElement.srcObject = stream;
            })
            .catch(function(error) {
                console.error('Erreur d\'accès à la webcam : ', error);
            });

        // Gestion du bouton de téléchargement
        var mediaRecorder;
        var recordedChunks = [];

        function startRecording() {
            recordedChunks = [];
            var stream = document.getElementById('live-video').captureStream();
            mediaRecorder = new MediaRecorder(stream, { mimeType: 'video/webm' });
            mediaRecorder.ondataavailable = function(event) {
                recordedChunks.push(event.data);
            };
            mediaRecorder.onstop = function() {
                downloadVideo();
            };
            mediaRecorder.start();
            downloadButton.classList.add('active');
        }

        function stopRecording() {
            mediaRecorder.stop();
            downloadButton.classList.remove('active');
        }

        function downloadVideo() {
            var blob = new Blob(recordedChunks, { type: 'video/webm' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = 'enregistrement.webm';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }

        var downloadButton = document.getElementById('download-button');
        downloadButton.addEventListener('click', function() {
            if (!mediaRecorder || mediaRecorder.state === 'inactive') {
                startRecording();
            } else {
                stopRecording();
            }
        });

        // Gestion de l'étirement
        var stretchButton = document.getElementById('stretch-button');
        var videoContainer = document.getElementById('video-container');
        var liveVideo = document.getElementById('live-video');
        var isStretched = false;

        stretchButton.addEventListener('click', function() {
            if (isStretched) {
                videoContainer.style.overflow = 'hidden';
                liveVideo.style.objectFit = 'contain';
                stretchButton.classList.remove('stretched');
                isStretched = false;
            } else {
                videoContainer.style.overflow = 'visible';
                liveVideo.style.objectFit = 'fill';
                stretchButton.classList.add('stretched');
                isStretched = true;
            }
        });
    </script>
</body>
</html>
"@

Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $siteContent

Import-Module WebAdministration
New-Website -Name "MonSite" -PhysicalPath "C:\inetpub\wwwroot" -Port $port -HostHeader $publicIP

Write-Output "Le site web est accessible à l'adresse : http://$publicIP:$port"
