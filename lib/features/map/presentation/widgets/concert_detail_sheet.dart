import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/concert.dart';
import '../providers/selected_concert_provider.dart';

class ConcertDetailSheet extends ConsumerStatefulWidget {
  const ConcertDetailSheet({super.key});

  @override
  ConsumerState<ConcertDetailSheet> createState() => _ConcertDetailSheetState();
}

class _ConcertDetailSheetState extends ConsumerState<ConcertDetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  Concert? _concert; // last non-null concert — kept during exit animation

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Clear the stored concert only after the sheet has fully slid off-screen
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _concert = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Concert?>(selectedConcertProvider, (_, next) {
      if (next != null) {
        setState(() => _concert = next);
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    if (_concert == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: DraggableScrollableSheet(
        initialChildSize: 0.42,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.42, 0.92],
        builder: (context, scrollController) {
          return _SheetContent(
            concert: _concert!,
            scrollController: scrollController,
            onClose: () =>
                ref.read(selectedConcertProvider.notifier).state = null,
          );
        },
      ),
    );
  }
}

// ── Sheet content ─────────────────────────────────────────────────────────────

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.concert,
    required this.scrollController,
    required this.onClose,
  });

  final Concert concert;
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // ── Drag handle ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B6B80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    concert.artistName,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  color: const Color(0xFF6B6B80),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Genre badge ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [_GenreBadge(genre: concert.genre)],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Divider(color: Color(0xFF2A2A3A), height: 1),
          ),

          // ── Venue & date ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: concert.venueName,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDate(concert.eventDate),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Ticket button ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: concert.ticketUrl != null
                ? _TicketButton(url: concert.ticketUrl!)
                : _NoTicketsLabel(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final local = date.toLocal();
    final weekday = weekdays[local.weekday - 1];
    final month = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$weekday ${local.day} $month ${local.year} · $hour:$minute';
  }
}

class _GenreBadge extends StatelessWidget {
  const _GenreBadge({required this.genre});
  final String genre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B6B80)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _TicketButton extends StatelessWidget {
  const _TicketButton({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: const Text(
          'Get Tickets',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NoTicketsLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No ticket link available',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
