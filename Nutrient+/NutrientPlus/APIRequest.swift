//
//  APIRequests.swift
//  NutrientPlus
//
//  Created by Victor Ye on 11/1/19.
//  Copyright © 2019 hoo. All rights reserved.
//

import Foundation
struct APIRequest{
    
    //Dictionary to simplify nutrient name
    let nutrientDictionary = [  "Energy":                               "Energy",       //1008
                                "Protein":                              "Protein",      //1003
                                "Carbohydrate, by difference":          "Carbs",        //1005
                                "Total lipid (fat)":                    "Fat",          //1004
                                "Thiamine":                             "B1",           //1165
                                "Riboflavin":                           "B2",           //1166
                                "Niacin":                               "B3",           //1167
                                "Pantothenic acid":                     "B5",           //1170
                                "Vitamin B-6":                          "B6",           //1175
                                "Vitamin B-12":                         "B12",          //1178
                                "Folate, total":                        "Folate",       //1187
                                "Vitamin A, IU":                        "Vitamin A",    //1104
                                "Vitamin C, total ascorbic acid":       "Vitamin C",    //1162
                                "Vitamin D":                            "Vitamin D",    //1110
                                "Vitamin E (label entry primarily)":    "Vitamin E",    //1124
                                "Vitamin K (phylloquinone)":            "Vitamin K",    //1185
                                "Calcium, Ca":                          "Calcium",      //1087
                                "Copper, Cu":                           "Copper",       //1098
                                "Iron, Fe":                             "Iron",         //1089
                                "Magnesium, Mg":                        "Magnesium",    //1090
                                "Manganese, Mn":                        "Manganese",    //1101
                                "Phosphorus, P":                        "Phosphorus",   //1091
                                "Potassium, K":                         "Potassium",    //1092
                                "Selenium, Se":                         "Selenium",     //1103
                                "Sodium, Na":                           "Sodium",       //1093
                                "Zinc, Zn":                             "Zinc",         //1095
                                "Sugars, total including NLEA":         "Sugar",        //2000
                                "Fiber, total dietary":                 "Fiber",        //1079
    
    ]
    
    let API_KEY = "LbcbTPKWh9DPSB2aMJnlOyABZKdtFAC9J2iheb0L"
    static let dispatchGroup = DispatchGroup() //Works sort of like a semaphore

    func getFoods(userInput: String) -> (Void){ //POST request to retrieve json of foods following APIStructs structure.
        APIRequest.dispatchGroup.enter() //mutex.lock
        //The following are the specifications for the POST request.
        let parameters = ["generalSearchInput":userInput]
        guard let urlPost = URL(string: "https://api.nal.usda.gov/fdc/v1/search?api_key=LbcbTPKWh9DPSB2aMJnlOyABZKdtFAC9J2iheb0L") else{ return }
        var request = URLRequest(url : urlPost)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return }
        request.httpBody = httpBody
        
        //The following is the URLSession or background service in which the API call happens.
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in //Do API call with specified request, and get data else fail.
            guard let data = data else { return }
            
            do {
                //JSONDecoder "translates" the data to follow the APIStructs structure, and sets this to foodDescription.
                let foodDescription = try JSONDecoder().decode(FoodDescription.self, from: data)
                
                //Loop through the "foods" array, and retrieve, store, and save as a card: the foodname, brandname, and foodID.
                for items in (foodDescription.foods){
                    let foodName = items.description
                    let brandName = items.brandOwner
                    let foodID = items.fdcId
                    let card = foodInfo(foodName: foodName, brandName: brandName ?? "N/A", foodID: foodID)
                    AddFoods.foodCards.append(card)
                
                }
                APIRequest.dispatchGroup.leave() //mutex.unlock
            } catch let jsonErr {
                print ("Error Serializing Json: ", jsonErr)
            }
        }.resume()
    }
    
    func getNutrients(foodID: Int) -> (Void){ //GET request to retrieve json of nutrients following APIStructs structure
        APIRequest.dispatchGroup.enter()
        AddFoods.nutrientCards = []
        let foodIDString = String(foodID)
        guard let urlGet = URL(string: "https://api.nal.usda.gov/fdc/v1/" + foodIDString + "?api_key=LbcbTPKWh9DPSB2aMJnlOyABZKdtFAC9J2iheb0L") else{ return }
        print (urlGet)
        let session = URLSession.shared
        session.dataTask(with: urlGet) {(data, response, error) in
            guard let data = data else { return }
            do {
                let nutrientDescription = try JSONDecoder().decode(NutrientDescription.self, from: data)
                for items in (nutrientDescription.foodNutrients){
                    let amount = items.amount
                    let unitName = items.nutrient.unitName
                    var nutrientName = items.nutrient.name
                    if (self.nutrientDictionary[nutrientName] != nil){
                        nutrientName = self.nutrientDictionary[nutrientName]!
                    }
                    let card = nutrientInfo(amount: amount, unitName: unitName, nutrientName: nutrientName)
                    //print(card)
                    AddFoods.nutrientCards.append(card)
                }
                APIRequest.dispatchGroup.leave()
            } catch let jsonErr {
                print ("Error Serializing Json: ", jsonErr)
            }
        }.resume()
    }
}
