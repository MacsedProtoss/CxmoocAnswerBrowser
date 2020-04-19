//
//  ContentView.swift
//  CxmoocAnswerBrowser
//
//  Created by Macsed on 2020/4/19.
//  Copyright © 2020 Macsed. All rights reserved.
//

import SwiftUI
import Alamofire

struct ContentView: View {
    
    @State var answerArr : Dictionary<String,String> = [:]
    @State var questions : String = ""
    @State var isEnabled = true
    @State var btnStr : String = "搜索"
    @State var answerText : String = "答案会显示在这里"
    @State var neededAnswerCount = 0
    
    var body: some View {
        VStack {
            Text("任何显示不全问题，请自行拉伸窗口解决。\n这是一个很简陋的超星题库搜索工具，问题请使用｜隔开，不要附带空格。\n使用第三方题库，如有问题请自行寻找其他题库接口代替。")
            TextField("输入题目，可以用｜分割", text: $questions)
            Button(action: {
                self.HandleBtnPressed()
                
            }) { Text(btnStr)
            }.disabled(!isEnabled)
            Text(answerText)
        }.padding()
    }
    
    func HandleBtnPressed(){
        isEnabled = false
        btnStr = "正在统计问题"
        var keywords : [String] = []
        var temp = ""
        for char in questions{
            let s = String(char)
            if s == "|" || s == "｜"{
                keywords.append(temp)
                temp = ""
            }else{
                temp = temp + s
            }
        }
        keywords.append(temp)
        btnStr = "共找到\(keywords.count)个问题"
        answerText = ""
        answerArr = [:]
        neededAnswerCount = keywords.count
        for question in keywords{
            getAnswer(with: question, on: requestCompletionHandler)
        }
        
    }
    
    func getAnswer(with question:String,on completion: @escaping ((String,String) -> Void)){
        AF.request("http://xdt.shuawk.top/biuapi.php?tm=\(question.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)").response { response in
            
            switch response.result{
                
            case .success(_):
                
                let decoder = JSONDecoder()
                
                if let result = response.data, let answerData = try? decoder.decode(answerBackJson.self, from: result) {
                    
                    completion(question,answerData.answer)
                    
                }else{
                    completion(question,"解析故障")
                }
                
            case .failure(_):
                
                completion(question,"网络故障")
            }
            
        }
    }
    
    func requestCompletionHandler(question:String,answer:String){
        answerArr[question] = answer
        if answerArr.count == neededAnswerCount{
            for (q,a) in answerArr{
                answerText = answerText + "\(q) 的答案是： \(a) \n"
            }
            isEnabled = true
            btnStr = "搜索"
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension String {
    var unicodeStr:String {
        let tempStr1 = self.replacingOccurrences(of: "\\u", with: "\\U")
        let tempStr2 = tempStr1.replacingOccurrences(of: "\"", with: "\\\"")
        let tempStr3 = "\"".appending(tempStr2).appending("\"")
        let tempData = tempStr3.data(using: String.Encoding.utf8)
        var returnStr:String = ""
        do {
            returnStr = try PropertyListSerialization.propertyList(from: tempData!, options: [.mutableContainers], format: nil) as! String
        } catch {
            print(error)
        }
        return returnStr.replacingOccurrences(of: "\\r\\n", with: "\n")
    }
}

struct answerBackJson : Codable {
    var tm : String
    var answer : String
    var api : String?
}
