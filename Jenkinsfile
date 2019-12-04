import java.nio.file.NoSuchFileException
def branch_n = env.BRANCH_NAME.replaceAll('/', '-')
ARTIFACTORY_INTERNAL_ID = "-1505608236@1461239289843"
ARTIFACTORY_PUBLIC_ID = "-1505608236@1461239289844"

properties([buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '20')), pipelineTriggers([])])


////////////////////////////////////////////////////
// Structure
// Branch:
//    master-release:     SitumWayfinding.framework.zip
//                        Goes to public artifactory
//                        Goes to libs-release-local/iOS/SitumSDK/<version>
//                        Release build
//
//    master:             SitumWayfinding.framework-<version>.zip
//                        Goes to libs-release-local/iOS/SitumSDK/master/<version>
//                        Release build
//
//    release_<version>:  SitumWayfinding.framework-<version>.zip
//                        Goes to libs-release-local/iOS/SitumSDK/release-<version>/<version>
//                        Release build
//
//    develop:            SitumWayfinding.framework-develop-<version>-DEV.zip
//                        Goes to libs-snapshot-local/iOS/SitumSDK/develop/<version>
//                        Debug build
//
//    feature/XXXX:       SitumWayfinding.framework-feature-XXXX-<version>-DEV.zip
//                        Goes to libs-snapshot-local/iOS/SitumSDK/feature-<branch_name>/<version>
//                        Debug build
////////////////////////////////////////////////////

////////////////////////////////////////////////////
// Read properties
////////////////////////////////////////////////////
def readProperties(String propertiesFile) {
    if (!fileExists(propertiesFile)){
        echo "No $propertiesFile"
        //TODO stop with appropiate methods
        throw new NoSuchFileException(propertiesFile)
    }
    def props = readProperties file: propertiesFile
    frameworkVersion = props["frameworkVersion"]
}

def getBuildType(String branch_n) {
  if (branch_n == 'master-release' || branch_n == 'master' || branch_n.startsWith("release-")) {
    return 'Release'
  } else {
    return 'Debug'
  }
}

def getZipName(String target, String buildType, String branch_n) {
  def midName = target == 'framework' ? '' : '.appledoc'

  if (buildType == 'Release' && branch_n == 'master-release'){
    return "SitumWayfinding${midName}.zip"
  } else if (buildType == 'Release'){
    return "SitumWayfinding${midName}-${frameworkVersion}.zip"
  } else {
    return "SitumWayfinding${midName}-${branch_n}-${frameworkVersion}-DEV.zip"
  }
}

def generateFolderName(String buildType) {
  return (buildType == 'Release') ? "libs-release-local" : "libs-snapshot-local"
}

def selectServer(String branch_n) {
  return branch_n.equals('master-release') ? ARTIFACTORY_PUBLIC_ID : ARTIFACTORY_INTERNAL_ID
}

def generateUploadSpec(String branchName, String version){
  def buildType = getBuildType(branchName)
  def folderName = generateFolderName(buildType)
  def docName = getZipName('docs', buildType, branchName)
  def branchNameIfPrivate = branchName.equals('master-release') ? "" : (branchName + '/')

  def text = """{
              "files":[
                  {
                    "pattern": "${docName}",
                    "target": "${folderName}/iOS/SitumWayfinding/${branchNameIfPrivate}${version}/"
                  }
                ]}"""

  return text
}

def uploadIOSArtifact(String branchName, String version){
    def artifactoryServer = Artifactory.server(selectServer(branchName))
    def uploadSpec = generateUploadSpec(branchName, version);
    artifactoryServer.upload(uploadSpec)
}

node('ios-slave') {
  stage('Checkout') {
    checkout scm
  }

  PROPERTIES_FILE = 'scripts/framework.properties'
  readProperties(PROPERTIES_FILE)

  // Install all the required pods
  stage('Install dependencies') {
    sh "pod repo update && pushd Example/ && pod install; popd"
  }

  // Build Example App
  stage('Build example app') {
    sh "/usr/local/bin/safe-xcode-select /Applications/Xcode.app"
    def buildType = getBuildType(branch_n)
    sh "bash scripts/compilation_wayfinding.sh ${buildType}"
  }

  // Generate appledoc for SitumWayfinding
  stage('Generate appledoc') {
    sh "/usr/local/bin/safe-xcode-select /Applications/Xcode.app"
    def buildType = getBuildType(branch_n)
    def zipName = getZipName('docs', buildType, branch_n)
    sh "bash scripts/generate_appledoc.sh ${zipName}"
  }

  // Archive the build logs
  stage('Archive build logs') {
    archiveArtifacts "build/buildWayfinding.log"
  }

  // Clean files from project build and docs generation
  stage('Clean workspace') {
    sh 'rm -rf build/'
    sh 'rm -rf docs/'
  }

  //  Upload artifact on result
  stage('Upload artifacts') {
    uploadIOSArtifact(branch_n, frameworkVersion)
  }

}
