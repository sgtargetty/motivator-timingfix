import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io';

class AmberAlertScreen extends StatefulWidget {
  final String? title;
  final String? message;
  final String? taskDescription;
  final Map<String, String?>? payload;
  final String? audioPath;

  const AmberAlertScreen({
    Key? key,
    this.title,
    this.message,
    this.taskDescription,
    this.payload,
    this.audioPath,
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
  bool _isEmergencyActive = true;
  bool _isAudioPlaying = false;
  int _audioPlayCount = 0;
  Timer? _emergencyTimer;
  Timer? _audioRetryTimer;

  @override
  void initState() {
    super.initState();
    print('🚨 AmberAlertScreen initializing...');
    
    _initializeAnimations();
    _setEmergencyAudioMode();
    _startEmergencyProtocol();
    
    // Keep screen on during emergency
    WakelockPlus.enable();
  }

  Future<void> _setEmergencyAudioMode() async {
    try {
      print('🔊 Setting emergency audio mode for emergency');
    } catch (e) {
      print('❌ Error setting emergency audio mode: $e');
    }
  }

  void _initializeAnimations() {
    // 🚨 Softer flashing background (less red)
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flashAnimation = ColorTween(
      begin: Colors.orange[800], // Changed from red[900] to orange
      end: Colors.orange[400],   // Changed from red[300] to orange
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));

    // 🚨 Gentler pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,  // Less dramatic scaling
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 🚨 Subtle shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: -3.0,  // Reduced shake intensity
      end: 3.0,
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
          await _audioPlayer.play();
          print('✅ Emergency audio played successfully');
        } else {
          print('❌ Audio file not found: ${widget.audioPath}');
        }
      } else {
        print('⚠️ No audio path provided for emergency');
      }
    } catch (e) {
      print('❌ Error playing emergency audio: $e');
      
      // Retry audio after 2 seconds
      _audioRetryTimer = Timer(const Duration(seconds: 2), () {
        if (_isEmergencyActive) {
          _isAudioPlaying = false;
          _playEmergencyAudio();
        }
      });
    } finally {
      // Reset audio flag after 3 seconds
      Timer(const Duration(seconds: 3), () {
        _isAudioPlaying = false;
      });
    }
  }

  void _triggerEmergencyVibration() {
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
    Timer(const Duration(milliseconds: 400), () {
      HapticFeedback.heavyImpact();
    });
  }

  Future<void> _dismissEmergency() async {
    print('🚨 Dismissing emergency alert...');
    
    try {
      setState(() {
        _isEmergencyActive = false;
      });
      
      // Stop all emergency processes
      _emergencyTimer?.cancel();
      _audioRetryTimer?.cancel();
      _flashController.stop();
      _pulseController.stop();
      _shakeController.stop();
      
      await _audioPlayer.stop();
      HapticFeedback.mediumImpact();
      
      // Disable screen lock
      WakelockPlus.disable();
      
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
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
                width: screenWidth,
                height: screenHeight,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _flashAnimation.value ?? Colors.orange[800]!, // Less red
                      Colors.black,
                    ],
                    stops: const [0.0, 1.0],
                    center: Alignment.center,
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView( // 🎯 FIX: Prevent overflow
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Reduced padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🎯 FIX: Better layout
                          children: [
                            // 🚨 TOP SECTION: Emergency content
                            Column(
                              children: [
                                SizedBox(height: screenHeight * 0.05), // Dynamic spacing
                                
                                // 🚨 Emergency Icon (smaller)
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(16), // Reduced from 20
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.6), // Less red
                                          blurRadius: 15, // Reduced shadow
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.warning_rounded,
                                      size: 60, // Reduced from 80
                                      color: Colors.orange, // Less red
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: screenHeight * 0.03),
                                
                                // 🚨 Emergency Title (smaller)
                                Text(
                                  widget.title ?? '🚨 EMERGENCY ALERT 🚨',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24, // Reduced from larger
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: screenHeight * 0.02),
                                
                                // 🚨 Emergency Message (compact)
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: screenHeight * 0.25, // Limit message height
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.message ?? 'Critical motivational emergency requires your immediate attention!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16, // Reduced font size
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: screenHeight * 0.02),
                                
                                // 🚨 Task Description (if provided)
                                if (widget.taskDescription != null && widget.taskDescription!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12), // Reduced padding
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3), // Less red
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          '📋 TASK',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.taskDescription!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            
                            // 🚨 BOTTOM SECTION: Dismiss button (always accessible)
                            Column(
                              children: [
                                // Audio status (compact debug info)
                                if (_audioPlayCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '🎵 Audio: $_audioPlayCount plays',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                
                                // 🚨 Dismiss Button (always visible and accessible)
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                    child: ElevatedButton(
                                      onPressed: _dismissEmergency,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.orange[800], // Less red
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        elevation: 8,
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
                                ),
                                
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 16), // Safe bottom padding
                              ],
                            ),
                          ],
                        ),
                      ),
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