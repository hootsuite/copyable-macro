# copyable-macro
Copyable is a Swift Macro used to bring Kotlin's `copy` functionality to Swift.
 

## Functionality
Creates a new instance of the struct with all properties copied from the original, allowing selective modification of specific properties while keeping others unchanged 

## Installation
TEST
TEST

## Usage

```
@Copyable
struct Student {
    let name: String
    let grade: Int
}

let student1 = Student(name: "Matthew", grade: 100)

print("name: \(student1.name) grade: \(student1.grade))

// should print: "name: Matthew grade: 100" 

let student 2 = student1.copy { student in  
    student.name = "Henry"
}

print("name: \(student2.name) grade: \(student2.grade))

// should print: "name: Henry grade: 100"
```
