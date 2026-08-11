mixin RMFuncts{
  static String getFirstLetters(String input) {
    if (input.isEmpty) return '';

    List<String> words = input.split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    // If only one word, return first two letters
    if (words.length == 1) {
      String singleWord = words[0];
      if (singleWord.length == 1) return singleWord.toUpperCase();
      return singleWord.substring(0, 2).toUpperCase();
    }

    // Multiple words: return first letter of each word
    return words.map((word) => word[0]).join().toUpperCase();
  }
  static String getTimeAgo(DateTime startTime, DateTime endTime) {
    Duration difference = endTime.difference(startTime);

    // Handle future dates
    if (difference.isNegative) {
      return 'in the future';
    }

    // Seconds
    if (difference.inSeconds < 60) {
      return 'just now';
    }

    // Minutes
    if (difference.inMinutes < 60) {
      int minutes = difference.inMinutes;
      return '$minutes min ago';
    }

    // Hours
    if (difference.inHours < 24) {
      int hours = difference.inHours;
      return '$hours hr ago';
    }

    // Days
    if (difference.inDays < 7) {
      int days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    }

    // Weeks
    if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }

    // Months
    if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }

    // Years
    int years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
  static String getDuration(DateTime start_date, DateTime end_date) {
    int years = end_date.year - start_date.year;
    int months = end_date.month - start_date.month;
    int days = end_date.day - start_date.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(end_date.year, end_date.month, 0); // last day of month before end_date's month
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    return "$years year${years == 1 ? '' : 's'} $months month${months == 1 ? '' : 's'} $days day${days == 1 ? '' : 's'}";
  }
}
