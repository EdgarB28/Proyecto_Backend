pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'edgargalvez'
    SERVER_IP      = '3.94.255.187'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build y push imagenes') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub',
                         usernameVariable: 'U', passwordVariable: 'P')]) {
          sh '''
            echo "$P" | docker login -u "$U" --password-stdin
            docker build -t $DOCKERHUB_USER/proyecto-backend:latest .
            docker build -t $DOCKERHUB_USER/db-backup:latest backup/
            docker push $DOCKERHUB_USER/proyecto-backend:latest
            docker push $DOCKERHUB_USER/db-backup:latest
          '''
        }
      }
    }

    stage('Deploy en el servidor') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'server-ssh', keyFileVariable: 'KEY'),
          string(credentialsId: 'db-password', variable: 'DBPASS'),
          string(credentialsId: 'aws-key-id', variable: 'AWS_ID'),
          string(credentialsId: 'aws-secret', variable: 'AWS_SECRET')
        ]) {
          sh '''
            SSH="ssh -i $KEY -o StrictHostKeyChecking=no ubuntu@$SERVER_IP"
            scp -i $KEY -o StrictHostKeyChecking=no docker-compose.yml ubuntu@$SERVER_IP:/opt/app/

            $SSH "cat > /opt/app/.env <<EOF
DOCKERHUB_USER=$DOCKERHUB_USER
DB_PASSWORD=$DBPASS
AWS_ACCESS_KEY_ID=$AWS_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET
EOF
chmod 600 /opt/app/.env"

            $SSH "cd /opt/app && docker compose pull && docker compose up -d"
            $SSH "(crontab -l 2>/dev/null | grep -v 'compose run' ; echo '0 */3 * * * cd /opt/app && docker compose run --rm backup >> /var/log/backup.log 2>&1') | crontab -"
          '''
        }
      }
    }
  }
}