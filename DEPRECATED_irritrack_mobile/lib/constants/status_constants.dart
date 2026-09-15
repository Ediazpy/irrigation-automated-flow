import 'package:flutter/material.dart';

class InspectionStatus {
  static const String assigned = 'assigned';
  static const String inProgress = 'in_progress';
  static const String review = 'review';
  static const String quoteSent = 'quote_sent';
  static const String completed = 'completed';

  static Color getColor(String status) {
    switch (status) {
      case assigned:
        return Colors.blue;
      case inProgress:
        return Colors.amber;
      case review:
        return Colors.orange;
      case quoteSent:
        return Colors.purple;
      case completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case assigned:
        return Icons.assignment_ind;
      case inProgress:
        return Icons.construction;
      case review:
        return Icons.rate_review;
      case quoteSent:
        return Icons.send;
      case completed:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}

class QuoteStatus {
  static const String draft = 'draft';
  static const String sent = 'sent';
  static const String viewed = 'viewed';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String expired = 'expired';

  static Color getColor(String status) {
    switch (status) {
      case draft:
        return Colors.grey;
      case sent:
        return Colors.blue;
      case viewed:
        return Colors.purple;
      case approved:
        return Colors.green;
      case rejected:
        return Colors.red;
      case expired:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case draft:
        return Icons.edit;
      case sent:
        return Icons.send;
      case viewed:
        return Icons.visibility;
      case approved:
        return Icons.check_circle;
      case rejected:
        return Icons.cancel;
      case expired:
        return Icons.timer_off;
      default:
        return Icons.help_outline;
    }
  }

  static String getDisplayName(String status) {
    switch (status) {
      case draft:
        return 'Draft';
      case sent:
        return 'Sent';
      case viewed:
        return 'Viewed';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case expired:
        return 'Expired';
      default:
        return status;
    }
  }
}

class RepairTaskStatus {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';

  static Color getColor(String status) {
    switch (status) {
      case pending:
        return Colors.grey;
      case assigned:
        return Colors.blue;
      case inProgress:
        return Colors.amber;
      case completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case pending:
        return Icons.pending;
      case assigned:
        return Icons.assignment_ind;
      case inProgress:
        return Icons.construction;
      case completed:
        return Icons.task_alt;
      default:
        return Icons.help_outline;
    }
  }

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case assigned:
        return 'Assigned';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      default:
        return status;
    }
  }
}

class TaskPriority {
  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String urgent = 'urgent';

  static Color getColor(String priority) {
    switch (priority) {
      case low:
        return Colors.grey;
      case normal:
        return Colors.blue;
      case high:
        return Colors.orange;
      case urgent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String priority) {
    switch (priority) {
      case low:
        return Icons.arrow_downward;
      case normal:
        return Icons.remove;
      case high:
        return Icons.arrow_upward;
      case urgent:
        return Icons.priority_high;
      default:
        return Icons.remove;
    }
  }
}
