/// Shot / dive direction for one kick (stored as -2 … 2 on the server).
enum PenaltyShootoutDir { farLeft, left, center, right, farRight }

/// Offline practice: classic three lanes or wide five. Online always uses [wide5].
enum PenaltyAimLanes { classic3, wide5 }

/// UI + gameplay step for the local client.
enum PenaltyShootoutPhase { pick, animating, reveal, finished }
