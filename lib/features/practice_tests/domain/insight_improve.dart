const kPracticeTopicImproveKey = 'practice_topic_improve';
const kPracticeTrapImproveKey = 'practice_trap_improve';

bool isInsightImproveFeature(String? key) =>
    key == kPracticeTopicImproveKey || key == kPracticeTrapImproveKey;
