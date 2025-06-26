import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'dart:io';

class AmberAlertScreen extends StatefulWidget {
  final String? title;
  final String? message;
  final String? audioPath;
  final String? taskDescription;
  final Map<String, dynamic>? payload;

  const AmberAlertScreen({
    Key? key,
    this.title,
    this.message,
    this.audioPath,
    this.taskDescription,
    this.payload,
  }) : super(key: key);

  @override
  State<AmberAlertScreen> createState() => _AmberAlertScreenState();
}

class _AmberAlertScreenState extends State<AmberAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<Color?> _flashAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _emergencyTimer;
  Timer? _audioRetryTimer;
  bool _isAudioPlaying = false;
  int _audioPlayCount = 0;
  bool _isEmergencyActive = true;

  @override
  void initState() {
    super.initState();
    print('🚨 AmberAlertScreen initializing...');
    _setupEmergencyMode();
    _initializeAnimations();
    _startEmergencyProtocol();
  }

  void _setupEmergencyMode() async {
    try {
      // 🚨 EMERGENCY: Keep screen on and prevent sleep
      await WakelockPlus.enable();
      print('✅ Wakelock enabled - screen will stay on');
      
      // 🚨 EMERGENCY: Set system UI to emergency mode
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.red,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.red,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      
      // 🚨 EMERGENCY: Override audio settings for emergency
      await _setEmergencyAudioMode();
      
      print('🚨 Emergency mode activated');
    } catch (e) {
      print('❌ Error setting up emergency mode: $e');
    }
  }

  Future<void> _setEmergencyAudioMode() async {
    try {
      // Set audio to emergency mode - override silent/DND
      await _audioPlayer.setVolume(1.0); // Maximum volume
      print('🔊 Audio set to maximum volume for emergency');
    } catch (e) {
      print('❌ Error setting emergency audio mode: $e');
    }
  }

  void _initializeAnimations() {
    // 🚨 Emergency flashing background
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flashAnimation = ColorTween(
      begin: Colors.red[900],
      end: Colors.red[300],
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));

    // 🚨 Emergency pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    // 🚨 Emergency shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.bounceInOut,
    ));

    // Start emergency animations
    _flashController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  void _startEmergencyProtocol() {
    print('🚨 Starting emergency protocol...');
    
    // Start emergency shake
    _startEmergencyShake();
    
    // Start emergency audio immediately
    _playEmergencyAudio();
    
    // Start emergency timer for continuous alerts
    _emergencyTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isEmergencyActive) {
        _playEmergencyAudio();
        _triggerEmergencyVibration();
      }
    });

    // Auto-dismiss after 5 minutes for safety
    Timer(const Duration(minutes: 5), () {
      if (mounted && _isEmergencyActive) {
        _dismissEmergency();
      }
    });
  }

  void _startEmergencyShake() {
    _shakeController.repeat(reverse: true);
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isEmergencyActive) {
        timer.cancel();
        return;
      }
      _shakeController.reset();
      _shakeController.forward();
    });
  }

  Future<void> _playEmergencyAudio() async {
    if (_isAudioPlaying || !_isEmergencyActive) return;
    
    _isAudioPlaying = true;
    _audioPlayCount++;
    
    try {
      print('🎵 Playing emergency audio (attempt $_audioPlayCount)');
      
      if (widget.audioPath != null && widget.audioPath!.isNotEmpty) {
        final file = File(widget.audioPath!);
        if (await file.exists()) {
          await _audioPlayer.setFilePath(widget.audioPath!);
          await _audioPlayer.setVolume(1.0); // Maximum volume
          await _audioPlayer.play();
          print('✅ Emergency audio playing from: ${widget.audioPath}');
        } else {
          print('❌ Audio file not found: ${widget.audioPath}');
          _playFallbackAlert();
        }
      } else {
        print('⚠️ No audio path provided, playing fallback');
        _playFallbackAlert();
      }
      
      // Trigger emergency vibration
      _triggerEmergencyVibration();
      
    } catch (e) {
      print('❌ Error playing emergency audio: $e');
      _playFallbackAlert();
    }
    
    // Reset audio playing flag after audio duration
    Timer(const Duration(seconds: 5), () {
      _isAudioPlaying = false;
    });
  }

  void _playFallbackAlert() {
    try {
      // Play system alert sound as fallback
      SystemSound.play(SystemSoundType.alert);
      print('🔔 Fallback system alert sound played');
    } catch (e) {
      print('❌ Error playing fallback alert: $e');
    }
  }

  void _triggerEmergencyVibration() {
    try {
      // Emergency vibration pattern: long-short-long-short
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.vibrate();
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        HapticFeedback.lightImpact();
      });
      print('📳 Emergency vibration triggered');
    } catch (e) {
      print('❌ Error triggering vibration: $e');
    }
  }

  void _dismissEmergency() async {
    print('🚨 Dismissing emergency alert...');
    _isEmergencyActive = false;
    
    try {
      // Stop all animations
      _flashController.stop();
      _pulseController.stop();
      _shakeController.stop();
      
      // Stop audio
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
      
      // Cancel timers
      _emergencyTimer?.cancel();
      _audioRetryTimer?.cancel();
      
      // Disable wakelock
      await WakelockPlus.disable();
      
      // Reset system UI
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
      
      print('✅ Emergency alert dismissed');
      
      // Navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error dismissing emergency: $e');
    }
  }

  @override
  void dispose() {
    print('🚨 AmberAlertScreen disposing...');
    _isEmergencyActive = false;
    _flashController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _audioPlayer.dispose();
    _emergencyTimer?.cancel();
    _audioRetryTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button during emergency (must tap dismiss)
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: Listenable.merge([_flashAnimation, _pulseAnimation, _shakeAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _flashAnimation.value ?? Colors.red[900]!,
                      Colors.black,
                    ],
                    stops: const [0.0, 1.0],
                    center: Alignment.center,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🚨 Emergency Icon
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.8),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              size: 80,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // 🚨 Emergency Title
                        Text(
                          widget.title ?? '🚨 EMERGENCY MOTIVATION ALERT',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.red,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 🚨 Emergency Message
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            widget.message ?? 
                            widget.taskDescription ??
                            'CRITICAL MOTIVATIONAL INTERVENTION REQUIRED!\n\n'
                            'Your success depends on taking action NOW. '
                            'This is your moment to push through and achieve greatness!',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 🚨 Emergency Status
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.volume_up, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Audio Play Count: $_audioPlayCount',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.screen_lock_portrait, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Screen Lock Override: ACTIVE',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 🚨 Dismiss Button
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: ElevatedButton(
                            onPressed: _dismissEmergency,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 10,
                            ),
                            child: const Text(
                              'DISMISS EMERGENCY ALERT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}