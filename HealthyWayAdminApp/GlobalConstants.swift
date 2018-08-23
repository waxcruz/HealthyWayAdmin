//
//  GlobalConstants.swift
//  LearnFirebaseAuthenticationAndAuthorization
//
//  Created by Bill Weatherwax on 8/22/18.
//  Copyright © 2018 waxcruz. All rights reserved.
//

import Foundation

enum Constants {
    //MARK: - Segue Names
    static let SEGUE_FROM_CREATE_TO_CLIENT_ID = "segueFromCreateToClientID"
    static let SEGUE_FROM_SIGNIN_TO_CLIENT_ID = "segueFromSignInToClientID"
    static let NOTICE_RESET_PASSWORD  = "Enter your account email address. You'll receive an email with instructions to reset your account password. Once you finish the reset of your password, login again"
    static let JOURNAL_MOCKUP = """
            <!DOCTYPE html>
            <html>
            <head>
            <style>
            table, th, td {
                border: 1px solid black;
                border-collapse: collapse;
            }
            </style>
            </head>
            <div style="overflow-x:auto;">
            </head>
            <body>
            <h2>Journal</h2>
            <p>08/04/2018</p>
            <table style="font-size:10px;">
                <col width="20">
                <col width="125">
                <col width="15">
                <col width="15">
                <col width="15">
                <col width="15">
                <col width="15">
                <col width="75">
              <tr>
                <th>Meal</th>
                <th>Food eaten</th>
                <th>P</th>
                <th>S</th>
                <th>V</th>
                <th>Fr</th>
                <th>F</th>
                <th>Feelings/Comments</th>
              </tr>
              <tr>
                <td>Daily Totals</td>
                <td> </td>
                <td>10</td>
                <td>3</td>
                <td>3</td>
                <td>2</td>
                <td>4</td>
                <td> </td>
              </tr>
              <tr>
                <td>Breakfast</td>
                <td>Greek Yogurt, peach, and Ryvita cracker</td>
                <td> 2</td>
                <td> 1</td>
                <td> 1</td>
                <td> .5</td>
                <td> 0</td>
                <td>Sat down to eat! Good behavior</td>
              </tr>
              <tr>
                <td>Snack</td>
                <td>2 egg omlet, Ezek. muffin, 1/2 c. of strawberries</td>
                <td> 0</td>
                <td> 1</td>
                <td> </td>
                <td> 1</td>
                <td> 0</td>
                <td> </td>
              </tr>
              <tr>
                <td>Lunch</td>
                <td>Chicken salad, dressing</td>
                <td> 4</td>
                <td> 0</td>
                <td> 2</td>
                <td> 0</td>
                <td> 2</td>
                <td>Hungry!</td>
              </tr>
               <tr>
                <td>Snack</td>
                <td>cut up veggies, 1 string cheese</td>
                <td> 1</td>
                <td> 0</td>
                <td> 2</td>
                <td> 0</td>
                <td> 0</td>
                <td>Cravings-veg & protein helped</td>
              </tr>
              <tr>
                <td>Dinner</td>
                <td>Salmon, sweet potatoe, salad, and broccoli</td>
                <td> 3</td>
                <td> 1</td>
                <td> 2</td>
                <td> 0</td>
                <td> 2</td>
                <td> </td>
              </tr>
              <tr>
                <td>Snack</td>
                <td>1/2 orange</td>
                <td> 0</td>
                <td> 0</td>
                <td>  </td>
                <td> .5</td>
                <td> 0</td>
                <td>Tired-got thru the day without suguar</td>
              </tr>
              <tr>
                <td>Totals</td>
                <td> </td>
                <td>10</td>
                <td>3</td>
                <td>7</td>
                <td>2</td>
                <td>4</td>
                <td> </td>
              </tr>
            </table>
            <font size="1">     Water: ✔︎✔︎✔︎✔︎✔︎✔︎✔︎✔︎ Supplements: ✔︎✔︎✔︎ Exercise: ✔︎</font>
            <p>
            <font size="1">I exercised as soon as I woke up & can this works best for me. I wanted sweets today after lunch. The H.W. supplements  helped ease the craving as did the snack. I am proud I did not give int to sugar. Yeah!!!</font>
            </p>
            </div>
            </body>
            </html>
            """

}
