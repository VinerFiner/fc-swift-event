//
//  EventController.swift
//  App
//
//  Created by vine on 2020/12/16.
//

import Vapor

struct EventController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("initialize", use: initialize)
        routes.post("invoke", use: invoke)
    }
    
    func initialize(req: Request) throws -> Response {
        let request_id = req.headers["x-fc-request-id"]
        let res = Response()
        res.body = .init(string: "Function is initialized, request_id:  \(request_id)\n")
        return res
    }
    
    struct InvokeInputJson: Content {
        let type: Int
        let path: String
        let msg: String?
    }
    struct InvokeOutputJson: Content {
        let request_id: String?
        let msg: String
        let subPaths: [String]?
        
        init(requestId: String?, msg: String, subPaths: [String]? = nil) {
            self.request_id = requestId
            self.msg = msg
            self.subPaths = subPaths
        }
    }
    /*
     curl -X POST -H "x-fc-request-id: test-request-1" 0.0.0.0:9000/invoke -d '{"type": 0, "path": "./"}'
     */
    func invoke(req: Request) throws -> InvokeOutputJson {
        let request_id = req.headers["x-fc-request-id"]
        print("FC Invoke Start RequestId: \(request_id)")
        
        let event = try? req.content.decode(InvokeInputJson.self, using: JSONDecoder())
        print("FC Invoke End RequestId: \(request_id)")
        let res = Response()
        res.headers = req.headers
        
        guard let invokeEvent = event else {
            return InvokeOutputJson(requestId: request_id.first, msg: "Hello from FC event function, No Content")
        }
        let sub = currentDir(type: invokeEvent.type, path: invokeEvent.path)
        return InvokeOutputJson(requestId: request_id.first, msg: "Hello from FC event function", subPaths: sub)
    }
}

extension EventController {
    /// 查看目录
    func currentDir(type: Int, path: String) -> [String]?{
        
        switch type {
        case -1:
            return deleteItem(atPath: path)
        case 0:
            return readContentOfDirectory(atPath: path)
        case 1000:
            return readSubpathsOfDirectory(atPath: path)
        default:
            return [path]
        }
    }
    
    /// 从指定目录读取文件
    func readContentOfDirectory(atPath path:String) -> [String]? {
        let manager = FileManager.default
        let contentsOfPath = try? manager.contentsOfDirectory(atPath: path)
        return contentsOfPath
    }
    
    /// 深度遍历，来展示目录下的所有文件
    func readSubpathsOfDirectory(atPath path:String) -> [String]? {
        let manager = FileManager.default
        let contentsOfPath = manager.subpaths(atPath: path)
        return contentsOfPath
    }
    /// 删除文件或者文件夹, 返回文件或者文件夹信息
    func deleteItem(atPath path: String) -> [String]? {
        let manager = FileManager.default
        let msgs = try? manager.attributesOfItem(atPath: path).map { (info) -> String in
            return "key: \(info.key) value:\(info.value)"
        }
        try? manager.removeItem(atPath: path)
        return msgs
    }
}

