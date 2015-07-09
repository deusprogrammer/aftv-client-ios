//
//  main.swift
//  JSON Parser v 0.1a
//
//  Created by Michael Main on 4/17/15.
//  Copyright (c) 2015 Michael Main. All rights reserved.
//
//  Change log
//  Michael Main | 04/21/2015 | Initial classes done- need to implement non string values

import Foundation

// Borrowed from http://benscheirman.com/2014/06/regex-in-swift/
// TODO Replace this later
class Regex {
    let internalExpression: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        var error: NSError?
        self.internalExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: &error)!
    }
    
    func test(input: String) -> Bool {
        let matches = self.internalExpression.matchesInString(input, options: nil, range:NSMakeRange(0, count(input)))
        return matches.count > 0
    }
}


// Needed to keep track of blob depth
struct Stack<T> {
    var items = [T]()
    mutating func push(item: T) {
        items.append(item)
    }
    mutating func pop() -> T {
        var item : T = items.removeLast()
        return item
    }
    func peek() -> T {
        return items.last!
    }
    func isEmpty() -> Bool {
        return items.count == 0
    }
    
    func displayStack() -> String {
        var s = ""
        var seperator = ""
        for item in items {
            s = "\(s)\(seperator)\(item)"
            seperator = ","
        }
        
        return s
    }
}

// A JSON parser that uses the default String type in Swift
class NBJSON {
    enum JsonType {
        case NONE
        case NULL
        case OBJECT
        case LIST
        case STRING
        case INT
        case FLOAT
        case BOOL
    }
    
    enum ParserState {
        case INIT
        case READING_KEY
        case SEARCHING_NEXT
        case SEARCHING_SEPERATOR
        case SEARCHING_VALUE
        case READING_STRING_VALUE
        case READING_NON_STRING_VALUE
        case READING_OBJECT_VALUE
        case READING_LIST_VALUE
    }
    
    class Parser {
        class func parseJson(jsonString : String) -> Any? {
            var jsonStringArray : Array<Character> = Array(jsonString)
            var index : Int
            var expression : Array<Character>
            var type : JsonType
            
            (index, expression, type) = extractJsonExpression(jsonString: jsonStringArray)
            
            if (type == JsonType.OBJECT) {
                return parseJsonObject(expression)
            } else if (type == JsonType.LIST) {
                return parseJsonList(expression)
            }
            
            return nil
        }
        
        private class func parseJsonList(jsonString : Array<Character>) -> Array<Any> {
            var type : JsonType
            var list  : Array<Any> = Array()
            var state : ParserState = ParserState.INIT
            var value : String = ""
            var index : Int
            var expression : Array<Character>
            
            for var i = 0; i < jsonString.count; i++ {
                var c = jsonString[i]
                
                switch (state) {
                case .INIT:
                    if (c == "\"") {
                        state = ParserState.READING_STRING_VALUE
                    } else if (c == "{") {
                        (index, expression, type) = extractJsonExpression(jsonString: jsonString, startIndex: i)
                        i = index
                        list.append(parseJsonObject(expression))
                        value = ""
                        state = ParserState.SEARCHING_NEXT
                    } else if (c == "[") {
                        (index, expression, type) = extractJsonExpression(jsonString: jsonString, startIndex: i)
                        i = index
                        list.append(parseJsonList(expression))
                        value = ""
                        state = ParserState.SEARCHING_NEXT
                    } else if (c != " " && c != "\t") {
                        value.append(c)
                        state = ParserState.READING_NON_STRING_VALUE
                    }
                    break
                case .READING_STRING_VALUE:
                    if (c == "\"") {
                        list.append(value)
                        value = ""
                        state = ParserState.SEARCHING_NEXT
                        continue
                    }
                    value.append(c)
                    break
                case .READING_NON_STRING_VALUE:
                    if (i == jsonString.count - 1) {
                        value.append(c)
                        c = ","
                    }
                    
                    if (c == ",") {
                        var type = determineType(String(value).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
                        switch (type) {
                        case .INT:
                            list.append((value as NSString).integerValue)
                            break
                        case .FLOAT:
                            list.append((value as NSString).floatValue)
                            break
                        case .BOOL:
                            list.append((value as NSString).boolValue)
                            break
                        case .STRING:
                            list.append(value)
                            break
                        case .NULL:
                            list.append(value)
                            break
                        default:
                            return Array()
                        }
                        
                        value = ""
                        state = ParserState.INIT
                        continue
                    }
                    value.append(c)
                    break
                case .SEARCHING_NEXT:
                    if (c == "," ) {
                        state = ParserState.INIT
                    }
                    break
                default:
                    break
                }
            }
            
            return list
        }
        
        private class func parseJsonObject(jsonString : Array<Character>) -> Dictionary<String, Any> {
            var type : JsonType
            var object : Dictionary<String, Any> = Dictionary()
            var state : ParserState = ParserState.INIT
            var key : String = ""
            var value : String = ""
            var index : Int
            var expression : Array<Character>
            
            for var i = 0; i < jsonString.count; i++ {
                var c = jsonString[i]
                
                switch (state) {
                case .INIT:
                    if (c == "\"") {
                        state = ParserState.READING_KEY
                    }
                    break
                case .READING_KEY:
                    if (c == "\"") {
                        state = ParserState.SEARCHING_SEPERATOR
                        continue
                    }
                    key.append(c)
                    break
                case .SEARCHING_SEPERATOR:
                    if (c == ":") {
                        state = ParserState.SEARCHING_VALUE
                    }
                    break
                case .SEARCHING_NEXT:
                    if (c == ",") {
                        state = ParserState.INIT
                    }
                    break
                case .SEARCHING_VALUE:
                    if (c == "\"") {
                        state = ParserState.READING_STRING_VALUE
                    } else if (c == "{") {
                        (index, expression, type) = extractJsonExpression(jsonString: jsonString, startIndex: i)
                        i = index
                        var obj = parseJsonObject(expression)
                        object[key] = obj
                        key = ""
                        value = ""
                        state = ParserState.SEARCHING_NEXT
                    } else if (c == "[") {
                        (index, expression, type) = extractJsonExpression(jsonString: jsonString, startIndex: i)
                        i = index
                        var list = parseJsonList(expression)
                        object[key] = list
                        key = ""
                        value = ""
                        state = ParserState.SEARCHING_NEXT
                    } else if (c != " " && c != "\t") {
                        value.append(c)
                        state = ParserState.READING_NON_STRING_VALUE
                    }
                    break
                case .READING_STRING_VALUE:
                    if (c == "\"") {
                        object[key] = value
                        key = ""
                        value = ""
                        state = ParserState.SEARCHING_NEXT
                        continue
                    }
                    value.append(c)
                    break
                case .READING_NON_STRING_VALUE:
                    if (i == jsonString.count - 1) {
                        value.append(c)
                        c = ","
                    }
                    
                    if (c == ",") {
                        var type = determineType(String(value).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
                        switch (type) {
                        case .INT:
                            object[key] = (value as NSString).integerValue
                            break
                        case .FLOAT:
                            object[key] = (value as NSString).floatValue
                            break
                        case .BOOL:
                            object[key] = (value as NSString).boolValue
                            break
                        case .STRING:
                            object[key] = value
                            break
                        case .NULL:
                            object[key] = nil
                            break
                        default:
                            return Dictionary()
                        }
                        
                        // Store the value if valid
                        key = ""
                        value = ""
                        state = ParserState.INIT
                        continue
                    }
                    value.append(c)
                    break
                default:
                    break;
                }
            }
            
            return object
        }
        
        private class func extractJsonExpression(#jsonString : Array<Character>, startIndex index : Int = 0) -> (Int, Array<Character>, JsonType) {
            var typeStack = Stack<String>()
            var jsonSubString = Array<Character>()
            var objectStarted = false
            var type : JsonType = JsonType.NONE;
            
            for var i = index; i < jsonString.count; i++ {
                var c = jsonString[i]
                
                if (objectStarted) {
                    jsonSubString.append(c)
                }
                
                if (c == "{") {
                    if (!objectStarted) {
                        type = JsonType.OBJECT
                    }
                    typeStack.push("{")
                    objectStarted = true
                } else if (c == "}" && typeStack.peek() == "{") {
                    typeStack.pop()
                } else if (c == "[") {
                    if (!objectStarted) {
                        type = JsonType.LIST
                    }
                    typeStack.push("[")
                    objectStarted = true
                } else if (c == "]" && typeStack.peek() == "[") {
                    typeStack.pop()
                } else if (c == "\"") {
                    if (typeStack.peek() == "\"") {
                        typeStack.pop()
                    } else {
                        if (!objectStarted) {
                            type = JsonType.STRING
                        }
                        typeStack.push("\"")
                        objectStarted = true
                    }
                }
                
                if (objectStarted && typeStack.isEmpty()) {
                    jsonSubString.removeLast()
                    return (i, jsonSubString, type)
                }
            }
            
            return (-1, Array(), JsonType.NONE)
        }
        
        private class func determineType(value: String) -> JsonType {
            var intRegex = "^[0-9]+$"
            var floatRegex = "^[0-9]+\\.+[0-9]+$"
            var boolRegex = "^(true|false)$"
            var nullRegex = "^null$"
            var stringRegex = "^\".*\"$"
            
            if (Regex(floatRegex).test(value)) {
                return JsonType.FLOAT
            } else if (Regex(intRegex).test(value)) {
                return JsonType.INT
            } else if (Regex(boolRegex).test(value)) {
                return JsonType.BOOL
            } else if (Regex(stringRegex).test(value)) {
                return JsonType.STRING
            } else if (Regex(nullRegex).test(value)) {
                return JsonType.NULL
            } else {
                return JsonType.NONE
            }
        }
    }
    
    class Utils {
        class func printJson(json: Any) {
            if (json is Dictionary<String, Any>) {
                printJsonObject(json: json as! Dictionary<String, Any>)
            } else if (json is Array<Any>) {
                printJsonList(json: json as! Array<Any>)
            }
        }
        
        private class func printJsonObject(#json: Dictionary<String, Any>, level: Int = 0) {
            for (key, value) in json {
                tabs(level)
                print("\(key) => ")
                if (value is Array<Any>) {
                    println()
                    printJsonList(json: value as! Array<Any>, level: level + 1)
                } else if (value is Dictionary<String, Any>) {
                    println()
                    printJsonObject(json: value as! Dictionary<String, Any>, level: level + 1)
                } else {
                    println(value)
                }
            }
        }
        
        private class func printJsonList(#json: Array<Any>, level: Int = 0) {
            for (index, value) in enumerate(json) {
                tabs(level)
                print("[\(index)] => ")
                if (value is Array<Any>) {
                    println()
                    printJsonList(json: value as! Array<Any>, level: level + 1)
                } else if (value is Dictionary<String, Any>) {
                    println()
                    printJsonObject(json: value as! Dictionary<String, Any>, level: level + 1)
                } else {
                    println(value)
                }
            }
        }
        
        private class func tabs(amount: Int) {
            for var i = 0; i < amount; i++ {
                print("\t")
            }
        }
    }
}

