//
//  UserVcViewController.swift
//  BravePlay
//
//  Created by yaosixu on 16/8/12.
//  Copyright © 2016年 Jason_Yao. All rights reserved.
//

import UIKit
import Result

class UserVcViewController: UIViewController {

    private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
    private let screenHeight: CGFloat = UIScreen.mainScreen().bounds.size.height
    private let titleCellIdentifier: String = "UserVcTitleViewTableViewCell"
    private let recommendCellIdentifier: String = "UserVcRecommendTableViewCell"
    private let customTableViewCellIdentifer: String = "UserCustomTableViewCell"
    private let titleInfoArray: [String] = ["相关推荐","所有视频"]
    private let tableView: UITableView = UITableView()
    private var userId: String = ""
    private var userName: String = ""
    private var headView: UserVcHeadView!

    private var userData: UserResponse = UserResponse()
    private var userRecommend: [UserRecommendResponse] = []
    private var userIssueVideos: [UserIssueVideosResponse] = []
    
    init(userId: String, userName: String) {
        self.userId = userId
        self.userName = userName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor ( red: 0.2431, green: 0.3412, blue: 0.3451, alpha: 1.0 )
        automaticallyAdjustsScrollViewInsets = false
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        let titleLabel = UILabel()
        titleLabel.frame.origin = CGPoint(x: 0.0, y: 0.0)
        titleLabel.text = userName
        titleLabel.textAlignment = .Center
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        requestUserData(userId)
        initTableView()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.hidden = false
        navigationController?.navigationBar.alpha = 0.0
    }
    
    private func initTableView() {
        tableView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        tableView.backgroundColor = UIColor.clearColor()
        view.addSubview(tableView)
        
        var nib = UINib(nibName: titleCellIdentifier, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: titleCellIdentifier)
        nib = UINib(nibName: recommendCellIdentifier, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: recommendCellIdentifier)
        nib = UINib(nibName: customTableViewCellIdentifer, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: customTableViewCellIdentifer)
        
        headView = UserVcHeadView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight / 2 - 30))
        tableView.tableHeaderView = headView
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .None
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    //滑动tableView显示navigation Bar
    func scrollViewDidScroll(scrollView: UIScrollView) {
        navigationController?.navigationBar.alpha = tableView.contentOffset.y / 150
    }
    
}

extension UserVcViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return userIssueVideos.count + 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch (indexPath.section, indexPath.row) {
        case (_ , 0):
            guard let cell = tableView.dequeueReusableCellWithIdentifier(titleCellIdentifier, forIndexPath: indexPath) as? UserVcTitleViewTableViewCell else {
                return UITableViewCell()
            }
            cell.titleLabel.text = titleInfoArray[indexPath.section]
            return cell
        case (0, _):
            guard let cell = tableView.dequeueReusableCellWithIdentifier(recommendCellIdentifier, forIndexPath: indexPath) as? UserVcRecommendTableViewCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            
            if userRecommend.count != 0 {
                cell.customCollectionView.reloadData()
                cell.takeData = { [unowned self] _ in
                    return self.userRecommend
                }
            }
            
            return cell
        default:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(customTableViewCellIdentifer, forIndexPath: indexPath) as? UserCustomTableViewCell else {
                return UITableViewCell()
            }
            
            let date = NSDate(timeIntervalSince1970: Double(userIssueVideos[indexPath.row - 1].created_at))
            let dateFormat = NSDateFormatter()
            dateFormat.dateFormat = "MM-dd"
            cell.timeLabel.text = dateFormat.stringFromDate(date)
            cell.coverImageView.setImageWithURL(makeImageURL(userIssueVideos[indexPath.row - 1].front_cover), defaultImage: UIImage(named: "find_mw_bg"))
            cell.titleLabel.text = userIssueVideos[indexPath.row - 1].title
            cell.nameLabel.text = userIssueVideos[indexPath.row - 1].topic.name
            
            cell.timeInfoLabel.text = {
                let mutines = userIssueVideos[indexPath.row - 1].duration / 60
                let seconds = userIssueVideos[indexPath.row - 1].duration % 60
                return "\(mutines)'\(seconds)"
            }()
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 && indexPath.row > 0 {
            let showVideos = HeadViewDetailForVideoViewController(name: userIssueVideos[indexPath.row].title, showId: "\(userIssueVideos[indexPath.row].id)")
            hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(showVideos, animated: true)
        }
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row > 0 {
            return 100
        } else if indexPath.section == 1 && indexPath.row > 0 {
            return 280
        } else {
            return 44
        }
    }
}

//请求数据
extension UserVcViewController : MoyaPares,UserVcRecommendTableViewCellDelegate {
    
    private func requestUserData(id: String) {
        MainSectionProvider.request(MainSection.Channels(id: id), completion: { [unowned self] result in
            self.showHud("正在加载")
            let resultData : Result<UserResponse, MyErrorType> = self.paresObject(result)
            switch resultData {
            case .Success(let data):
                self.userData = data
                self.userRecommends(id)
            case .Failure(let error):
                self.popHud()
                self.dealWithError(error)
            }
        })
    }
    
    private func userRecommends(id: String) {
        MainSectionProvider.request(MainSection.UserRecommends(id: id), completion: { [unowned self] result in
            self.showHud("正在加载")
            let resultData : Result<[UserRecommendResponse], MyErrorType> = self.paresObjectArray(result)
            switch resultData {
            case .Success(let data):
                self.userRecommend = data
                self.userUpLoadVideos(id)
            case .Failure(let error):
                self.popHud()
                self.dealWithError(error)
            }
            })
    }
    
    private func userUpLoadVideos(id: String) {
        MainSectionProvider.request(MainSection.UserUpLoadVideos(id: id), completion: { [unowned self] result in
            self.showHud("正在加载")
            let resultData : Result<[UserIssueVideosResponse], MyErrorType> = self.paresObjectArray(result)
            switch resultData {
            case .Success(let data):
                self.userIssueVideos = data
                self.popHud()
                self.setHeadView()
                self.tableView.reloadData()
            case .Failure(let error):
                self.popHud()
                self.dealWithError(error)
            }
            })
    }
    
    private func setHeadView() {
        headView.introduce = userData.description
        headView.nick = userData.name
        headView.headImageUrl = userData.avatar
    }
    
    func tapCollectionView(index: Int) {
        let user = UserVcViewController(userId: "\(userRecommend[index].id)", userName: userRecommend[index].name)
        hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(user, animated: true)
    }
    
}

