//
//  CKRecordContext.swift
//  
//
//  Created by Nofel Mahmood on 21/06/2015.
//
//

import UIKit
import CloudKit

class CKRecordContext: NSObject {
   
    var operationQueue:NSOperationQueue = NSOperationQueue()
    var ckModifyRecordsOperation:CKModifyRecordsOperation?
    var deletedRecords:Array<CKRecordID> = Array<CKRecordID>()
    var modifiedRecords:Array<CKRecord> = Array<CKRecord>()
    var database:CKDatabase?
    var recordsZone:CKRecordZone?
    
    /**
    Initializes the context with an instance of CKDatabase.
    
    :param: database   Database to use for performing operations in the context. Private or Public
    
    */
    init(database:CKDatabase?) {
        
        self.database = database
        super.init()
    }
    
    /**
    Inserts and returns a new CKRecord with the specified record type in the context.
    
    :param: recordType   RecordType to use to initialize a new CKRecord
    
    :returns: An instance of newly initialized CKRecord
    */
    func insertNewCKRecord(recordType:String)->CKRecord
    {
        var ckRecord:CKRecord = CKRecord(recordType: recordType)
        self.modifiedRecords.append(ckRecord)
        return ckRecord
    }
    
    /**
    Inserts and returns a new CKRecord with the specified record type and recordID in the context.
    
    :param: recordType   RecordType to use to initialize a new CKRecord
    :param: recordID     CKRecordID to use to initialize a new CKRecord
    
    :returns: An instance of newly initialized CKRecord
    */
    func insertNewCKRecord(recordType:String,recordID:CKRecordID)->CKRecord
    {
        var ckRecord:CKRecord = CKRecord(recordType: recordType, recordID: recordID)
        self.modifiedRecords.append(ckRecord)
        return ckRecord
    }
    
    /**
    Inserts and returns a new CKRecord with the specified record type and recordZoneID in the context.
    
    :param: recordType       RecordType to use to initialize a new CKRecord
    :param: recordZoneID     CKRecordZoneID to use to initialize a new CKRecord
    
    :returns: An instance of newly initialized CKRecord
    */
    func insertNewCKRecord(recordType:String,recordZoneID:CKRecordZoneID)->CKRecord
    {
        var ckRecord:CKRecord = CKRecord(recordType: recordType, zoneID: recordZoneID)
        self.modifiedRecords.append(ckRecord)
        return ckRecord
    }
    
    /**
    Fetches and returns an instance of CKRecord with the provided recordID.
    
    :param: recordID   CKRecordID to use to fetch the record
    
    :returns: An instance of CKRecord
    */
    func fetchCKRecord(recordID:CKRecordID)->CKRecord?
    {
        var fetchRecordsOperation:CKFetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordsOperation.database = self.database
        var record:CKRecord?
        fetchRecordsOperation.fetchRecordsCompletionBlock = ({(recordsWithRecordIDs,error) -> Void in
            
            if error == nil
            {
                record = recordsWithRecordIDs[recordID] as? CKRecord
                self.modifiedRecords.append(record!)
            }
        })
        self.operationQueue.addOperation(fetchRecordsOperation)
        self.operationQueue.waitUntilAllOperationsAreFinished()
        
        return record
    }
    
    /**
    Fetches instances of CKRecords from CKDatabase with the given recordType and predicate
    
    :param: recordType       RecordType used to fetch records of the type.
    :param: predicate        A Predicate to filter the records.
    
    :returns: An array of CKRecords.
    */

    func fetchCKRecords(recordType:String,predicate:NSPredicate)->[CKRecord]?
    {
        var query:CKQuery = CKQuery(recordType: recordType, predicate: predicate)
        var queryOperation:CKQueryOperation = CKQueryOperation(query: query)
        var fetchedRecords:Array<CKRecord> = Array<CKRecord>()
        queryOperation.queryCompletionBlock = ({(queryCursor, error) -> Void in
            
            if error != nil
            {
                
            }
        })
        queryOperation.recordFetchedBlock = ({(ckRecord) -> Void in
            
            fetchedRecords.append(ckRecord)
        })
        
        self.operationQueue.addOperation(queryOperation)
        self.operationQueue.waitUntilAllOperationsAreFinished()
        
        return fetchedRecords
    }
    
    /**
    Deletes the record from the CKDatabase
    
    :param: record   Record that is to be deleted from the database
    */
    func deleteRecord(record:CKRecord)
    {
        self.deletedRecords.append(record.recordID)
    }
    
    /**
    Resets the context removing all the pending deletions, insertions and modifications.
    */
    func reset()
    {
        self.modifiedRecords.removeAll(keepCapacity: false)
        self.deletedRecords.removeAll(keepCapacity: false)
    }
    
    /**
    Commits all the changes to CKDatabase.
    
    :param: error   A error pointer
    
    */
    func save(error:NSErrorPointer)
    {
        self.ckModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: self.modifiedRecords, recordIDsToDelete: self.deletedRecords)
        self.ckModifyRecordsOperation?.database = self.database
        self.ckModifyRecordsOperation?.modifyRecordsCompletionBlock = ({(savedRecords, deletedRecordsIDs, operationError) -> Void in
            
            if operationError != nil
            {
                error.memory = operationError
            }
        })
        self.operationQueue.addOperation(self.ckModifyRecordsOperation!)
        self.operationQueue.waitUntilAllOperationsAreFinished()
    }
    
}
