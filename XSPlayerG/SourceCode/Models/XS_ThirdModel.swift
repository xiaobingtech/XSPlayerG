//
//  XS_ThirdModel.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/23.
//

import Foundation

class XS_DoubanRecommendModel: XS_Model, Equatable {
    static func == (lhs: XS_DoubanRecommendModel, rhs: XS_DoubanRecommendModel) -> Bool {
        lhs.name == rhs.name
    }
    var img: String = ""
    var name: String = ""
    var score: String = ""
}

class XS_DoubanHotModel: XS_Model {
    var subjects: [_Subjects] = []
    class _Subjects: XS_Model {
        var episodes_info: String = ""
        var rate: String = ""
        var cover_x: Int = 0 // 1400
        var title: String = "" // "要久久爱"
        var url: String = "" // "https:\/\/movie.douban.com\/subject\/36097798\/"
        var playable: Bool = false // true
        var cover: String = "" // "https://img3.doubanio.com\/view\/photo\/s_ratio_poster\/public\/p2903422342.webp"
        var id: String = "" // "36097798"
        var cover_y: Int = 0 // 1985
        var is_new: Bool = false // true
        
        func xs_toVideoModel() -> XS_VideoModel {
            let model = XS_VideoModel()
            model.vod_id = id
            model.vod_name = title
            model.vod_remarks = episodes_info
            model.vod_pic = cover
            return model
        }
    }
}

class XS_QuarkHotModel: XS_Model {
    var success: Bool = false
    var code: String = ""
    var msg: String = ""
    var data: _Data = .init()
    class _Data: XS_Model {
        var allUserRes: _AllUserRes = .init()
        class _AllUserRes: XS_Model {
            var hot_search_movie: [_HotSearchMovie] = []
            class _HotSearchMovie: XS_Model {
                var items: [_Items] = []
                class _Items: XS_Model {
                    var category: String = "" // "实时热门"
                    var mid: String = "" // "1686693790"
                    var list: [_List] = []
                    class _List: XS_Model {
                        var name: String = "" // "变形金刚：超能勇士崛起"
                        var video_tag: String = "" // "预告片"
                        var douban_rate: String = "" // "6.3"
                        var description1: String = "" // "2023 / 美国 / 动作 科幻 / 安东尼·拉莫斯 多米尼克·菲什巴克 彼特·库伦 朗·普尔曼 彼特·丁拉基 杨紫琼"
                        var description2: String = "" // "上世纪90年代，反派宇宙大帝从天而降，驱使以天灾为首的恐惧兽掀起地球危机。绝境之中，蛰伏许久的巨无霸终觉醒。"
                        var cover_url: String = "" // "https://gw.alicdn.com/imgextra/i3/O1CN01jvV0pX1IZS4MOUIoC_!!6000000000907-0-tps-270-400.jpg"
                        var video_cover_url: String = "" // "https://gw.alicdn.com/imgextra/i4/O1CN01MJ04ci1K5LGUsWM19_!!6000000001112-0-tps-952-485.jpg"
                        var target_url: String = "" // "https://quark.sm.cn/s?q=%E5%8F%98%E5%BD%A2%E9%87%91%E5%88%9A%EF%BC%9A%E8%B6%85%E8%83%BD%E5%8B%87%E5%A3%AB%E5%B4%9B%E8%B5%B7&uc_param_str=dnntnwvepffrgibijbprsvpidsdichei&from=kkframenew&by=submit&snum=0"
                        var video_url: String = "" // "https://www.douban.com/doubanapp/dispatch?uri=/movie/26634250/trailer%3Ftrailer_id%3D303939%26trailer_type%3DA&dt_dapp=1"
                        
                        func xs_toVideoModel() -> XS_VideoModel {
                            let model = XS_VideoModel()
                            model.vod_id = name
                            model.vod_name = name
                            model.vod_remarks = video_tag
                            model.vod_pic = cover_url
                            return model
                        }
                    }
                }
            }
        }
    }
}

class XS_BaiduHotModel: XS_Model {
    var ResultCode: Int = -1
    var Result: [_Result] = []
    class _Result: XS_Model {
        var DisplayData: _DisplayData = .init()
        class _DisplayData: XS_Model {
            var resultData: _ResultData = .init()
            class _ResultData: XS_Model {
                var tplData: _TplData = .init()
                class _TplData: XS_Model {
                    var result: _Result = .init()
                    class _Result: XS_Model {
                        var result: [_Result] = []
                        class _Result: XS_Model {
                            var additional: String = "" // "全39集"
                            var ename: String = "" // "狂飙"
                            var img: String = "" // "http://t10.baidu.com/it/u=903003438,971221855&fm=58&app=83&f=JPEG?w=270&h=404"
                            var urlsign: String = "" // "9668235497655341878"
                            
                            func xs_toVideoModel() -> XS_VideoModel {
                                let model = XS_VideoModel()
                                model.vod_id = urlsign
                                model.vod_name = ename
                                model.vod_remarks = additional
                                model.vod_pic = img
                                return model
                            }
                        }
                    }
                }
            }
        }
    }
}

class XS_KyLiveHotModel: XS_Model {
    var status: Bool = false
    var message: String = ""
    var data: [_Data] = []
    class _Data: XS_Model {
        var vid: String = "" // "4748"
        var cs: Int = 0 // 2
        var rk_cg: Int = 0 // 0
        var hl: String = "" // "NO.1 X6,TOP3 X6"
        var r_days: Int = 0 // 6
        var caid: String = "" // 1340536
        var rk: Int = 0 // 1
        var hot: Int = 0 // 18064
        var epg: String = "" // "繁花"
        var b_date: String = "" // "2023-12-27"
        var chs: String = "" // "13"
        var plts: String = "" // "1"
        
        func xs_toVideoModel() -> XS_VideoModel {
            let model = XS_VideoModel()
            model.vod_id = caid
            model.vod_name = epg
            model.vod_hot = hot
            return model
        }
    }
}

class XS_EnlightentHotModel: XS_Model {
    var content: [_Content] = []
    class _Content: XS_Model {
        var nameId: String = ""
        var name: String = ""
        var allHot: Int = 0
        
        func xs_toVideoModel() -> XS_VideoModel {
            let model = XS_VideoModel()
            model.vod_id = nameId
            model.vod_name = name
            model.vod_hot = allHot
            return model
        }
    }
}
