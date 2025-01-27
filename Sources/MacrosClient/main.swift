//Copyright © 2024 Hootsuite Media Inc. All rights reserved.

import Macros

//MARK: @Copyable example

@Copyable
struct Student {
    let name: String
    let grade: Int
    
    // if default params are to be used, must create custom init methods like below
    init(
        name: String = "1",
        grade: Int = 2
    ) {
        self.name = name
        self.grade = grade
    }
}

let student1 = Student(name: "Matt", grade: 100)
let student2 = student1.copy { $0.name = "Borys" }

print("\(student1.name) has a grade of \(student1.grade)")
print("\(student2.name) has a grade of \(student2.grade)")

// Copyable can also be used with vars

@Copyable
struct Hotel {
    var name: String
    var foundingYear: Int
}

let hotel = Hotel(name: "Hootsuite Inn", foundingYear: 2021)
let newHotel = hotel.copy { $0.name = "Hootsuite Tower" }

print("\(hotel.name) was founded in \(hotel.foundingYear)")
print("\(newHotel.name) was founded in \(newHotel.foundingYear)")

