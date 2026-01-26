import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';

/// Widget to display quiz statistics for a specific category
class CategoryQuizStatsCard extends StatefulWidget {
  final int categoryId;
  final VoidCallback? onTakeQuiz;
  final VoidCallback? onViewHistory;

  const CategoryQuizStatsCard({
    super.key,
    required this.categoryId,
    this.onTakeQuiz,
    this.onViewHistory,
  });

  @override
  State<CategoryQuizStatsCard> createState() => _CategoryQuizStatsCardState();
}

class _CategoryQuizStatsCardState extends State<CategoryQuizStatsCard> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await QuizService.getCategoryQuizStats(widget.categoryId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Kiểm tra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (_stats != null && (_stats!['totalQuizzes'] ?? 0) > 0)
                  TextButton(
                    onPressed: widget.onViewHistory,
                    child: Text('Xem lịch sử'),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorState()
            else if (_stats == null || (_stats!['totalQuizzes'] ?? 0) == 0)
                _buildNoQuizState()
              else
                _buildStatsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 40),
          SizedBox(height: 8),
          Text('Không thể tải dữ liệu', style: TextStyle(color: Colors.red)),
          TextButton(
            onPressed: _loadStats,
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuizState() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.psychology,
                size: 48,
                color: Colors.orange.shade300,
              ),
              SizedBox(height: 12),
              Text(
                'Chưa có bài kiểm tra nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Làm bài kiểm tra để đánh giá kiến thức của bạn!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onTakeQuiz,
            icon: Icon(Icons.play_arrow),
            label: Text('Bắt đầu kiểm tra'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContent() {
    final totalQuizzes = _stats!['totalQuizzes'] ?? 0;
    final passedQuizzes = _stats!['passedQuizzes'] ?? 0;
    final averageScore = (_stats!['averageScore'] ?? 0.0).toDouble();
    final highestScore = (_stats!['highestScore'] ?? 0.0).toDouble();
    final passRate = totalQuizzes > 0
        ? (passedQuizzes / totalQuizzes * 100).toStringAsFixed(0)
        : '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: totalQuizzes.toString(),
                label: 'Bài kiểm tra',
                icon: Icons.assignment,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: '${averageScore.toStringAsFixed(1)}%',
                label: 'Điểm TB',
                icon: Icons.analytics,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: '$passRate%',
                label: 'Tỷ lệ đạt',
                icon: Icons.check_circle,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (highestScore > 0) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điểm cao nhất',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${highestScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                _buildGradeBadge(_getGrade(highestScore)),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onTakeQuiz,
            icon: Icon(Icons.play_arrow),
            label: Text('Làm bài kiểm tra mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeBadge(String grade) {
    Color color;
    switch (grade) {
      case 'A':
        color = Colors.green;
        break;
      case 'B':
        color = Colors.blue;
        break;
      case 'C':
        color = Colors.orange;
        break;
      case 'D':
        color = Colors.deepOrange;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          grade,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display overall quiz statistics on profile/dashboard
class OverallQuizStatsWidget extends StatefulWidget {
  final bool compact;

  const OverallQuizStatsWidget({
    super.key,
    this.compact = false,
  });

  @override
  State<OverallQuizStatsWidget> createState() => _OverallQuizStatsWidgetState();
}

class _OverallQuizStatsWidgetState extends State<OverallQuizStatsWidget> {
  QuizStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await QuizService.getQuizStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_stats == null || _stats!.totalQuizzes == 0) {
      return widget.compact ? SizedBox() : _buildEmptyState();
    }

    return widget.compact ? _buildCompactView() : _buildFullView();
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Chưa có bài kiểm tra nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    final stats = _stats!;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, color: Colors.orange),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${stats.totalQuizzes} bài kiểm tra',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Điểm TB: ${stats.averageScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${stats.passedQuizzes}/${stats.totalQuizzes}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    final stats = _stats!;
    final passRate = stats.passRate;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Thống kê kiểm tra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    stats.totalQuizzes.toString(),
                    'Tổng bài',
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    stats.passedQuizzes.toString(),
                    'Đạt',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    '${stats.averageScore.toStringAsFixed(0)}%',
                    'Điểm TB',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Tỷ lệ đạt',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: passRate / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  passRate >= 70 ? Colors.green : Colors.orange,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${passRate.toStringAsFixed(1)}% bài kiểm tra đạt yêu cầu',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display quiz history list
class QuizHistoryList extends StatefulWidget {
  final int? categoryId;
  final int maxItems;
  final bool showViewAll;
  final VoidCallback? onViewAll;

  const QuizHistoryList({
    super.key,
    this.categoryId,
    this.maxItems = 5,
    this.showViewAll = true,
    this.onViewAll,
  });

  @override
  State<QuizHistoryList> createState() => _QuizHistoryListState();
}

class _QuizHistoryListState extends State<QuizHistoryList> {
  List<QuizResultModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await QuizService.getQuizHistory(categoryId: widget.categoryId);
      if (mounted) {
        setState(() {
          _history = history.take(widget.maxItems).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Chưa có lịch sử kiểm tra',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showViewAll)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch sử kiểm tra',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_history.length >= widget.maxItems)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: Text('Xem tất cả'),
                  ),
              ],
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          itemBuilder: (context, index) => _buildHistoryItem(_history[index]),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(QuizResultModel result) {
    final isPassed = result.score >= 60;
    final quizTypeLabel = _getQuizTypeLabel(result.quizType);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPassed ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              result.grade,  // ✅ FIX: Non-nullable giờ
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
        title: Text(
          quizTypeLabel,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${result.correctAnswers}/${result.totalQuestions} câu đúng • ${_formatDate(result.completedAt)}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPassed ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${result.score.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getQuizTypeLabel(String quizType) {
    switch (quizType.toUpperCase()) {
      case 'QUICK_TEST':
        return 'Kiểm tra nhanh';
      case 'FULL_TEST':
        return 'Kiểm tra đầy đủ';
      case 'LISTENING_TEST':
      case 'LISTENING':
        return 'Kiểm tra nghe';
      case 'WRITING_TEST':
      case 'WRITING':
        return 'Kiểm tra viết';
      case 'MIXED_TEST':
      case 'MIXED':
        return 'Kiểm tra tổng hợp';
      default:
        return 'Kiểm tra';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Quick quiz start button widget
class QuickQuizButton extends StatelessWidget {
  final int categoryId;
  final VoidCallback? onPressed;
  final bool mini;

  const QuickQuizButton({
    super.key,
    required this.categoryId,
    this.onPressed,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.quiz, color: Colors.orange),
        tooltip: 'Kiểm tra nhanh',
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.flash_on),
      label: Text('Kiểm tra nhanh'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}