import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// Live Classes Screen
/// API: GET  /api/v1/courses/{courseId}/live-sessions
///      POST /api/v1/live-sessions/{sessionId}/join  → returns join token/url
class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key});

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _upcoming = [];
  List<dynamic> _past = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.get(AppConstants.liveSessionsBase);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final rawData = body['data'];
        List<dynamic> all = [];
        if (rawData is List) {
          all = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          all = rawData['content'];
        }
        setState(() {
          _upcoming = all.where((s) {
            final status = s['status']?.toString() ?? '';
            return status == 'SCHEDULED' || status == 'LIVE';
          }).toList();
          _past = all.where((s) {
            final status = s['status']?.toString() ?? '';
            return status == 'ENDED' || status == 'COMPLETED' || status == 'CANCELLED';
          }).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _upcoming = [];
          _past = [];
          _loading = false;
          _error = 'Failed to fetch live sessions from backend.';
        });
      }
    } catch (_) {
      setState(() {
        _upcoming = [];
        _past = [];
        _loading = false;
        _error = 'Network error loading live sessions.';
      });
    }
  }

  String _selectedCategoryPill = 'All Video';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> get _filteredUpcoming {
    var list = _upcoming;
    if (_selectedCategoryPill == 'Live') {
      list = list.where((s) => s['status'] == 'LIVE').toList();
    } else if (_selectedCategoryPill == 'New Upload') {
      list = list.where((s) => s['status'] == 'SCHEDULED').toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final title = (s['title'] ?? '').toString().toLowerCase();
        final instructor = (s['instructorName'] ?? '').toString().toLowerCase();
        return title.contains(q) || instructor.contains(q);
      }).toList();
    }
    return list;
  }

  List<dynamic> get _filteredPast {
    if (_selectedCategoryPill == 'Live' || _selectedCategoryPill == 'New Upload') {
      return [];
    }
    var list = _past;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final title = (s['title'] ?? '').toString().toLowerCase();
        final instructor = (s['instructorName'] ?? '').toString().toLowerCase();
        return title.contains(q) || instructor.contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _join(dynamic session) async {
    final sessionId = session['id']?.toString() ?? '';
    final title = session['title']?.toString() ?? 'Live Session';
    final instructor = session['instructorName']?.toString() ?? 'Instructor';
    final isLive = session['status']?.toString() == 'LIVE';

    try {
      ApiClient.post('${AppConstants.liveSessionsBase}/$sessionId/join', {});
    } catch (_) {}

    if (!mounted) return;

    if (isLive) {
      // Open Live Interactive Streaming Player Modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LivePlayerModal(title: title, instructor: instructor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('RSVP confirmed for "$title"! 🔔'),
        backgroundColor: AppTheme.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Electric Blue Header matching Dream Theme Screen 3
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const Text('Video Learning',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearching = !_isSearching;
                                if (!_isSearching) {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }
                              });
                            },
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: _isSearching ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                                size: 20,
                                color: _isSearching ? AppTheme.primary : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isSearching) ...[
                        const SizedBox(height: 14),
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                                  cursorColor: AppTheme.primary,
                                  decoration: const InputDecoration(
                                    hintText: 'Search live classes & sessions...',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      // Horizontal Category Filter Pills matching Dream Theme Screen 3
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHeaderPill('All Video'),
                            const SizedBox(width: 8),
                            _buildHeaderPill('Live'),
                            const SizedBox(width: 8),
                            _buildHeaderPill('New Upload'),
                            const SizedBox(width: 8),
                            _buildHeaderPill('Trending'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: _loading
                      ? _shimmer()
                      : _error != null
                          ? _errorState()
                          : TabBarView(
                              controller: _tab,
                              children: [
                                _SessionList(sessions: _filteredUpcoming, onJoin: _join,
                                    emptyMsg: 'No live classes found.'),
                                _SessionList(sessions: _filteredPast, onJoin: null,
                                    emptyMsg: 'No past sessions found.'),
                              ],
                            ),
                ),
              ],
            ),
            // Floating "Sort By" button matching Dream Theme Screen 3
            Positioned(
              bottom: 20,
              left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showSortDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swap_vert_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Sort By', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule_rounded, color: AppTheme.primary),
              title: const Text('Scheduled Time'),
              onTap: () { Navigator.pop(context); setState(() {}); },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up_rounded, color: AppTheme.primary),
              title: const Text('Most Popular'),
              onTap: () { Navigator.pop(context); setState(() {}); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPill(String label) {
    final isSelected = _selectedCategoryPill == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryPill = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : Colors.white,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(16),
    child: Shimmer.fromColors(
      baseColor: AppTheme.bgSection,
      highlightColor: AppTheme.bgSecondary,
      child: Column(children: List.generate(4, (_) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 120,
        decoration: BoxDecoration(color: AppTheme.bgSection,
            borderRadius: BorderRadius.circular(16)),
      ))),
    ),
  );

  Widget _errorState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textDisabled),
      const SizedBox(height: 16),
      Text(_error ?? 'Something went wrong', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _load, child: const Text('Retry')),
    ],
  ));
}

class _SessionList extends StatelessWidget {
  final List<dynamic> sessions;
  final Function(dynamic)? onJoin;
  final String emptyMsg;
  const _SessionList({required this.sessions, required this.onJoin,
      required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, size: 56,
              color: AppTheme.textDisabled),
          const SizedBox(height: AppTheme.sp16),
          Text(emptyMsg, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp8),
      itemBuilder: (_, i) {
        final s = sessions[i];
        final isLive = s['status']?.toString() == 'LIVE';
        return Container(
          padding: const EdgeInsets.all(AppTheme.sp16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: isLive ? AppTheme.error : AppTheme.divider,
              width: isLive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (isLive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('● LIVE NOW',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: AppTheme.sp8),
                ],
                Expanded(
                  child: Text(s['title']?.toString() ?? 'Live Session',
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: AppTheme.sp8),
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(s['instructorName']?.toString() ?? 'Instructor',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: AppTheme.sp16),
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(s['scheduledAt']?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              if (onJoin != null) ...[
                const SizedBox(height: AppTheme.sp16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: Text(isLive ? 'Join Live Class Now' : 'RSVP for Session'),
                    onPressed: () => onJoin!(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? AppTheme.error : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LivePlayerModal extends StatefulWidget {
  final String title;
  final String instructor;
  const _LivePlayerModal({required this.title, required this.instructor});

  @override
  State<_LivePlayerModal> createState() => _LivePlayerModalState();
}

class _LivePlayerModalState extends State<_LivePlayerModal> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'user': 'Dr. Aris Thorne', 'text': 'Welcome everyone to today’s live stream!'},
    {'user': 'Sophia Chen', 'text': 'Super excited for the Q&A session!'},
    {'user': 'Rahul', 'text': 'Can we cover microservices architecture today?'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Modal Drag Indicator & Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(6)),
                                child: const Text('● LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(widget.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Instructor: ${widget.instructor}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Stream Player View
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, const Color(0xFF0F172A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isVideoOff ? Icons.videocam_off_rounded : Icons.sensors_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text(_isVideoOff ? 'Camera Off' : 'Live Broadcast Active', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: const Text('142 Viewers', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          // Controls (Mute, Camera, Leave)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _isMuted ? Colors.redAccent : Colors.white12, shape: BoxShape.circle),
                    child: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _isVideoOff ? Colors.redAccent : Colors.white12, shape: BoxShape.circle),
                    child: Icon(_isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(22)),
                    child: Row(
                      children: const [
                        Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Live Chat Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text('Live Chat', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: '${m['user']}: ', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              TextSpan(text: m['text'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Say something in live chat...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white12,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                        onPressed: () {
                          if (_chatController.text.trim().isNotEmpty) {
                            setState(() {
                              _messages.add({'user': 'You', 'text': _chatController.text.trim()});
                              _chatController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
