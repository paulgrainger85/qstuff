pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
                touch /tmp/pgriggy.test
            }
        }
    }
    post { 
        always { 
            echo 'I will always say Hello again!'
        }
    }
}
