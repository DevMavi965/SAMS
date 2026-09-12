import 'package:local_auth/local_auth.dart';

class BiometricService {
  final localAuth=LocalAuthentication();
  Future<(bool,String)> authenticateUser()async{
    bool isAuthenticated;
    try {
      isAuthenticated = await localAuth.authenticate(
          localizedReason: "Please authenticate to proceed",
          biometricOnly: true
      );
      return (true,"Authentication successful");
    }on  LocalAuthException catch(e){
      switch(e.code){
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricHardware:
          return (false,"No biometric enrolled,please set biometric on your device first");
        case LocalAuthExceptionCode.biometricLockout:
          return (false,"Too many attempts,try later");
        case LocalAuthExceptionCode.userCanceled:
          return (false,"Authentication canceled by user");
        default:
          return (false,"An error occurred during authentication");
      }

    }
  }
}