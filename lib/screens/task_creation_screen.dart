import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import 'package:motivator_ai/models/task.dart';
import 'package:motivator_ai/services/task_storage.dart';
import 'package:motivator_ai/services/motivator_api.dart';

class TaskCreationScreen extends StatefulWidget {
  const TaskCreationScreen({Key? key}) : super(key: key);

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  late AnimationController _micController;
  late AnimationController _saveController;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  
  late Animation<double> _micScale;
  late Animation<double> _micRotation;
  late Animation<double> _saveScale;
  late Animation<Color?> _saveColor;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;
  late Animation<double> _pulseScale;

  bool _isListening = false;
  bool _isLoadingAI = false;
  bool _isSaving = false;
  DateTime? _selectedDateTime;
  final TaskStorage _storage = TaskStorage();
  final MotivatorApi _api = MotivatorApi();

  final List<String> _quickSuggestions = [
    "🏃‍♂️ Go for a run",
    "📚 Read for 30 minutes",
    "🧘‍♀️ Meditate and center myself",
    "💪 Complete workout routine",
    "🎯 Focus on priority project",
    "📞 Call someone I care about",
    "🌱 Learn something new",
    "✨ Practice gratitude",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cardController.forward();
  }

  void _setupAnimations() {
    _micController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _saveController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _micScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _micController, curve: Curves.elasticOut),
    );

    _micRotation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );

    _saveScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _saveController, curve: Curves.easeInOut),
    );

    _saveColor = ColorTween(
      begin: Colors.teal,
      end: Colors.green,
    ).animate(_saveController);

    _cardSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty || _selectedDateTime == null) {
      _showErrorFeedback();
      return;
    }

    setState(() => _isSaving = true);
    _saveController.forward();
    HapticFeedback.mediumImpact();

    try {
      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descController.text,
        scheduledTime: _selectedDateTime!,
      );

      await _storage.saveTask(task);
      
      // Success animation
      await Future.delayed(const Duration(milliseconds: 500));
      HapticFeedback.heavyImpact();
      
      // Navigate back with success
      Navigator.pop(context);
    } catch (e) {
      _showErrorFeedback();
    } finally {
      setState(() => _isSaving = false);
      _saveController.reverse();
    }
  }

  void _showErrorFeedback() {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please fill in title and select date/time'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.selectionClick();
    picker.DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      onConfirm: (date) {
        setState(() => _selectedDateTime = date);
        HapticFeedback.lightImpact();
      },
      currentTime: DateTime.now(),
      theme: const picker.DatePickerTheme(
        backgroundColor: Color(0xFF1a1a2e),
        itemStyle: TextStyle(color: Colors.white),
        doneStyle: TextStyle(color: Colors.tealAccent),
      ),
    );
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _micController.forward();
      _speech.listen(onResult: (val) {
        setState(() {
          _titleController.text = val.recognizedWords;
        });
      });
    }
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();
    await _speech.stop();
    setState(() => _isListening = false);
    _micController.reverse();
  }

  Future<void> _useAISuggestion() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoadingAI = true);
    
    try {
      final suggestion = await _api.generateLine("Give me a motivational task idea");
      _titleController.text = suggestion;
      _descController.text = "AI-generated task. Customize as needed! 🤖";
      setState(() {
        _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorFeedback();
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  void _selectQuickSuggestion(String suggestion) {
    HapticFeedback.selectionClick();
    _titleController.text = suggestion;
    setState(() {
      _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _micController.dispose();
    _saveController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create Your Mission',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _cardController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _cardSlide.value),
            child: Opacity(
              opacity: _cardOpacity.value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0f0f23),
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section
                        _buildHeaderSection(),
                        
                        const SizedBox(height: 30),
                        
                        // Main form
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTaskInputCard(),
                                const SizedBox(height: 20),
                                _buildDescriptionCard(),
                                const SizedBox(height: 20),
                                _buildDateTimeCard(),
                                const SizedBox(height: 20),
                                _buildAISuggestionCard(),
                                const SizedBox(height: 20),
                                _buildQuickSuggestionsCard(),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Save button
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 What needs your energy today?',
          style: TextStyle(
            color: Colors.tealAccent,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Turn your intention into unstoppable action',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  color: Colors.tealAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Task Title',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _micController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _micScale.value,
                      child: Transform.rotate(
                        angle: _micRotation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isListening 
                                ? Colors.red.withOpacity(0.2)
                                : Colors.tealAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening ? Colors.red : Colors.tealAccent,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : Colors.tealAccent,
                            ),
                            onPressed: _isListening ? _stopListening : _startListening,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g., Complete my morning workout',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.tealAccent),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseScale.value,
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Listening... Speak your task!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notes_outlined, color: Colors.tealAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Description (Optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add more details about your mission...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.tealAccent),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_outlined, color: Colors.tealAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'When will you conquer this?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedDateTime != null 
                      ? Colors.tealAccent.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDateTime != null
                        ? Colors.tealAccent
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedDateTime != null 
                          ? Colors.tealAccent 
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDateTime == null
                          ? 'Tap to set date & time'
                          : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} at ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _selectedDateTime != null 
                            ? Colors.tealAccent 
                            : Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Need inspiration?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Let AI spark your motivation',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _isLoadingAI ? null : _useAISuggestion,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _isLoadingAI
                      ? null
                      : const LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                        ),
                  color: _isLoadingAI ? Colors.grey : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingAI)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.psychology, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isLoadingAI ? 'Thinking...' : '🧠 Inspire Me!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Quick Ideas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickSuggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () => _selectQuickSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedBuilder(
      animation: _saveController,
      builder: (context, child) {
        return Transform.scale(
          scale: _saveScale.value,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _saveColor.value ?? Colors.teal,
                  Colors.tealAccent,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Creating Your Mission...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Launch Your Mission! 🚀',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}