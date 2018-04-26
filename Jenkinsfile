pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                sh 'touch /tmp/test_hello'
            }
        }
        stage('NextExample') {
            steps{
                echo 'Another hello' 
            }
        }
    }
    post { 
        always { 
            echo 'I will always say Hello again!'
        }
    }
}
