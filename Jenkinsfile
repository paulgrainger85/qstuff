pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
            steps{
                touch /tmp/pgriggy
            }
        }
    }
    post { 
        always { 
            echo 'I will always say Hello again!'
        }
    }
}
