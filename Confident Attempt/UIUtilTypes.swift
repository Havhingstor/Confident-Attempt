import Confident_Attempt_Model

enum PeriodScale: String {
    case days = "days"
    case weeks = "weeks"
    case months = "months"
    case years = "years"
    
    func toCalculationStart(withNum: UInt) -> CalculationStart {
        switch self {
            case .days:
                    .days(number: withNum)
            case .weeks:
                    .weeks(number: withNum)
            case .months:
                    .months(number: withNum)
            case .years:
                    .years(number: withNum)
        }
    }
    
    static func fromCalculationStart(_ start: CalculationStart) -> Self {
        switch start {
            case .days(_):
                    .days
            case .weeks(_):
                    .weeks
            case .months(_):
                    .months
            case .years(_):
                    .years
        }
    }
}
