package cachet.plugins.health

import io.objectbox.annotation.DatabaseType
import io.objectbox.annotation.Entity
import io.objectbox.annotation.Id
import io.objectbox.annotation.Type

@Entity
class SensorStep {
    @Id
    var id: Long = 0
    @Type(DatabaseType.DateNano)
    var startTime: Long? = 0
    @Type(DatabaseType.DateNano)
    var endTime: Long? = 0
    var count: Double = 0.0
}