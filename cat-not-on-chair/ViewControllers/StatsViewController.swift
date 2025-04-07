import UIKit

class StatsViewController: UIViewController {
    private let sessionManager = FocusSessionManager.shared
    
    // MARK: - UI Components
    private lazy var weeklyStatsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var monthlyStatsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateStats()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Statistics"
        
        view.addSubview(weeklyStatsLabel)
        view.addSubview(monthlyStatsLabel)
        
        NSLayoutConstraint.activate([
            weeklyStatsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weeklyStatsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            weeklyStatsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            weeklyStatsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            monthlyStatsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            monthlyStatsLabel.topAnchor.constraint(equalTo: weeklyStatsLabel.bottomAnchor, constant: 40),
            monthlyStatsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            monthlyStatsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Helpers
    private func updateStats() {
        let weeklyStats = sessionManager.getWeeklyStats()
        let monthlyStats = sessionManager.getMonthlyStats()
        
        weeklyStatsLabel.text = """
        Weekly Statistics:
        Total Sessions: \(weeklyStats.totalSessions)
        Completed: \(weeklyStats.completedSessions)
        Failed: \(weeklyStats.failedSessions)
        """
        
        monthlyStatsLabel.text = """
        Monthly Statistics:
        Total Sessions: \(monthlyStats.totalSessions)
        Completed: \(monthlyStats.completedSessions)
        Failed: \(monthlyStats.failedSessions)
        """
    }
} 