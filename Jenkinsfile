pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
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
