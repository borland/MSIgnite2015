// Copyright (c) 2015 Orion Edwards
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

class MainTabBarController : UITabBarController {
    override func viewDidLoad() {
        guard let storyboard = self.storyboard else {
            return
        }
        
        let tueVc = storyboard.instantiateViewControllerWithIdentifier("SessionListViewController") as! SessionListViewController
        let wedVc = storyboard.instantiateViewControllerWithIdentifier("SessionListViewController") as! SessionListViewController
        let thuVc = storyboard.instantiateViewControllerWithIdentifier("SessionListViewController") as! SessionListViewController
        let friVc = storyboard.instantiateViewControllerWithIdentifier("SessionListViewController") as! SessionListViewController
        
        tueVc.setLabel("Tuesday", imageName:"T", dayId:1);
        wedVc.setLabel("Wednesday", imageName:"W", dayId:2);
        thuVc.setLabel("Thurday", imageName:"T", dayId:3);
        friVc.setLabel("Friday", imageName:"F", dayId:4);
        
        setViewControllers([tueVc, wedVc, thuVc, friVc], animated: false)
    }
}
