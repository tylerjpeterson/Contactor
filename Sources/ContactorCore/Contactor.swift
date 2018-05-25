//
//  Contactor.swift
//  Contactor
//
//  Created by Tyler Peterson on 04/18/18.
//  Copyright © 2018 Kettle. All rights reserved.
import Foundation
import Contacts

/// Provides a simplified API to search contacts, determine their existence, and create new contacts via Apple's Contacts framework.
///
/// - Requires: Apple Contacts Framework - `import Contacts`
/// - SeeAlso: [Contacts Framework documentation](https://developer.apple.com/documentation/contacts)
public class Contactor {

	/// Reference to local CNContactStore instance
	let store: CNContactStore = CNContactStore()

	/// Flag set to record whether or not access to contacts has been granted
	var hasPermission: Bool = false

	var iCloudIdentifier: String?

	/// Initializes a new Contactor instance
	public init() {
		store.requestAccess(for: CNEntityType.contacts) {granted, error in
			if (error != nil) {
				print(error!.localizedDescription)
				exit(0)
			} else if !granted {
				print("Access denied.")
				exit(0)
			} else {
				self.hasPermission = true
				do {
					let containers = try self.store.containers(matching: nil)
					for container in containers {
						if container.name == "iCloud" {
							self.iCloudIdentifier = container.identifier
							break
						}
					}
				} catch let err {
					print(err)
				}
			}
		}
	}

	public func createGroup(name: String = "New Group") -> CNGroup? {
		do {
			let groups = try self.store.groups(matching: nil)
			let filteredGroups = groups.filter { $0.name == name }

			if filteredGroups.count > 0 {
				return filteredGroups[0]
			}

			let newGroup = CNMutableGroup()
			let saveRequest = CNSaveRequest()

			newGroup.name = name
			saveRequest.add(newGroup, toContainerWithIdentifier: nil)

			do {
				try self.store.execute(saveRequest)
				return newGroup
			} catch let error {
				print(error.localizedDescription)
				return nil
			}
		} catch {
			return nil
		}
	}

	public func searchGroups(filter: String = "*", completion: @escaping (_ results: [CNGroup]) -> Void) {
		do {
			let groups: [CNGroup] = try self.store.groups(matching: nil)

			if filter == "*" {
				completion(groups)
			} else {
				completion(groups.filter { $0.name.lowercased() == filter.lowercased() })
			}
		} catch {
			completion([])
		}
	}

	/// Search user contacts against a filter, and optionally export the results as a collection of VCFs
	///
	/// - Parameters:
	///   - filter: The string to filter contact names against
	///   - deepSearch: Search all contact properties for "filter"
	///   - output: Directory to write output files to
	///   - format: Format of returned results
	///   - completion: Completion handler returning output in requested format as a String
	public func searchContacts(filter: String = "*", deepSearch: Bool = false, output: String? = nil, format: String = "text", completion: @escaping (_ results: String) -> Void) {
		if deepSearch {
			self.findContactsDeep(matching: filter) {(result: [CNContact]?) in
				completion(self.formatSearchResults(filter: filter, output: output, format: format, result: result!))
			}
		} else {
			self.findContacts(matching: filter) {(result: [CNContact]?) in
				completion(self.formatSearchResults(filter: filter, output: output, format: format, result: result!))
			}
		}
	}

	public func updateContact(existing: CNContact, contact: [String: String], completion: @escaping (_ result: Bool) -> Void) {
		let newContact = self.parseContact(contact: contact, existing: existing)
		let saveRequest = CNSaveRequest()
		saveRequest.update(newContact)

		do {
			try self.store.execute(saveRequest)
			completion(true)
		} catch let err {
			print(err)
			completion(false)
		}
	}

	/// Search user contacts against a filter, returning ContactRecord instances
	///
	/// - Parameters:
	///   - filter: The string to filter contact names against
	///   - completion: Completion handler returning output as a collection of ContactRecord instances
	public func searchContactRecords(filter: String = "*", deepSearch: Bool = false, completion: @escaping (_ results: [ContactRecord]) -> Void) {
		var contactRecords: [ContactRecord] = []

		if deepSearch {
			self.findContactsDeep(matching: filter) {(result: [CNContact]?) in
				for contact in result! {
					contactRecords.append(ContactRecord(contactInstance: contact))
				}

				completion(contactRecords)
			}
		} else {
			self.findContacts(matching: filter) {(result: [CNContact]?) in
				for contact in result! {
					contactRecords.append(ContactRecord(contactInstance: contact))
				}

				completion(contactRecords)
			}
		}
	}

	/// Determines if and how many contacts match the passed search criteria, writing the number of matches to stdout
	///
	/// - Parameters:
	///   - filter: The string to filter contact names against
	///   - deepSearch: Search all contact properties for "filter"
	///   - completion: Completion handler passing the number of matching contacts
	public func contactExists(filter: String, deepSearch: Bool = false, completion: @escaping (_ results: Int) -> Void) {
		if deepSearch {
			self.findContactsDeep(matching: filter) {(result: [CNContact]?) in
				completion(result?.count ?? 0)
			}
		} else {
			self.findContacts(matching: filter) {(result: [CNContact]?) in
				completion(result?.count ?? 0)
			}
		}
	}

	private func parseContact(contact: [String: String], existing: CNContact? = nil) -> CNMutableContact {
		var newContact: CNMutableContact

		if existing != nil {
			newContact = existing?.mutableCopy() as! CNMutableContact
		} else {
			newContact = CNMutableContact()
		}

		let homeAddress = CNMutablePostalAddress()
		let birthday = NSDateComponents()
		let emailAddresses = contact["email"]?.components(separatedBy: ",") ?? [""]
		let phoneNumbers = contact["phone"]?.components(separatedBy: ",") ?? [""]
		var numbers: [CNLabeledValue<CNPhoneNumber>] = []
		var emails: [CNLabeledValue<NSString>] = []

		for email in emailAddresses {
			if email.contains(":") {
				let parts = email.split(separator: ":").map({ (address) -> String in
					return address.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
				})

				emails.append(CNLabeledValue(
					label: parts.first!,
					value: NSString.init(string: parts.last!)))
			} else {
				emails.append(CNLabeledValue(
					label: "personal",
					value: NSString.init(string: email)))
			}
		}

		for number in phoneNumbers {
			if number.contains(":") {
				let parts = number.split(separator: ":").map({ (phone) -> String in
					return phone.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
				})

				numbers.append(CNLabeledValue(
					label: parts.first!,
					value: CNPhoneNumber(stringValue: parts.last!)))
			} else {
				numbers.append(CNLabeledValue(
					label: CNLabelPhoneNumberiPhone,
					value: CNPhoneNumber(stringValue: number)))
			}
		}

		newContact.jobTitle = contact["title"]!
		newContact.organizationName = contact["company"]!
		newContact.givenName = contact["first"]!
		newContact.familyName = contact["last"]!
		newContact.emailAddresses = emails
		newContact.phoneNumbers = numbers
		homeAddress.street = contact["street"]!
		homeAddress.city = contact["city"]!
		homeAddress.state = contact["state"]!
		homeAddress.postalCode = contact["zip"]!
		newContact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: homeAddress)]

		if contact["birthday"] != "" && contact["birthmonth"] != "" {
			birthday.day = Int(contact["birthday"]!)!
			birthday.month = Int(contact["birthmonth"]!)!
			newContact.birthday = birthday as DateComponents
		}

		if contact["pic"] != "" {
			let data = NSData(contentsOfFile: contact["pic"]!)
			newContact.imageData = data! as Data
		}

		return newContact
	}

	/// Adds a contact to the user's default contact group
	///
	/// - Parameters:
	///   - contact: Dictionary of properties and values used to create the contact
	///   - completion: Completion handler passing the newly created CNContact's identifier
	public func addContact(contact: [String: String], groupId: String = "", completion: @escaping (_ createdContactIdentifier: String?) -> Void) {
		let saveRequest = CNSaveRequest()
		let newContact = self.parseContact(contact: contact)
		saveRequest.add(newContact, toContainerWithIdentifier: self.iCloudIdentifier)

		do {
			if groupId.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
				let groupIdentifierPredicate: NSPredicate = CNGroup.predicateForGroups(withIdentifiers: [groupId])
				let contactGroup = try self.store.groups(matching: groupIdentifierPredicate)

				if (contactGroup.count > 0) {
					saveRequest.addMember(newContact, to: contactGroup.first!)
				}
			}

			try self.store.execute(saveRequest)
			completion(newContact.identifier)
		} catch {
			print("Error storing contact: \(error)")
			completion(nil)
		}
	}

	/// Remove a contact based on its identifier
	///
	/// - Parameters:
	///   - id: Identifier of contact to be removed
	///   - completion: Completion handler passed true on success, false on failure
	public func removeContact(id: String, completion: @escaping (_ result: Bool) -> Void) {
		let keysToFetch: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor]

		do {
			let request: CNSaveRequest = CNSaveRequest()
			let identifierPredicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: [id])
			let contacts: [CNContact] = try store.unifiedContacts(matching: identifierPredicate, keysToFetch: keysToFetch)

			if contacts.count > 0 {
				let contact: CNContact! = contacts.first
				let mutable: CNMutableContact = contact.mutableCopy() as! CNMutableContact

				request.delete(mutable)
				try self.store.execute(request)
				completion(true)
			} else {
				completion(false)
			}
		} catch {
			print("Error removing contact: \(error)")
			completion(false)
		}
	}

	/// Remove a group and all of its contacts
	///
	/// - Parameters:
	///   - id: Identifier of the group to be removed
	///   - completion: Completion handler with boolean indicating if removal was successful
	public func removeGroup(id: String, completion: @escaping (_ result: Bool) -> Void) {
		let keysToFetch: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor]
		let groupPredicate: NSPredicate = CNGroup.predicateForGroups(withIdentifiers: [id])
		let contactPredicate: NSPredicate = CNContact.predicateForContactsInGroup(withIdentifier: id)

		do {
			let request: CNSaveRequest = CNSaveRequest()
			let groups: [CNGroup]! = try self.store.groups(matching: groupPredicate)

			if groups.count > 0 {
				let contacts: [CNContact] = try self.store.unifiedContacts(matching: contactPredicate, keysToFetch: keysToFetch)
				let total: Int = contacts.count
				var done: Int = 0

				for contact in contacts {
					let mutable: CNMutableContact = contact.mutableCopy() as! CNMutableContact
					request.delete(mutable)
					try self.store.execute(request)
					done += 1

					if done >= total {
						request.delete(groups.first?.mutableCopy() as! CNMutableGroup)
						try self.store.execute(request)
						completion(true)
					}
				}
			} else {
				completion(false)
			}
		} catch {
			print("Error removing contact: \(error)")
			completion(false)
		}
	}

	/// Retrieves a collection of ContactRecords representing all CNContacts within the specified CNGroup
	///
	/// - Parameters:
	///   - groupId: Target group's identifier
	///   - completion: Completion handler with matching ContactRecords
	public func getContactsInGroup(groupId: String, completion: @escaping (_ contacts: [ContactRecord]) -> Void) {
		let contactPredicate: NSPredicate = CNContact.predicateForContactsInGroup(withIdentifier: groupId)
		let keysToFetch: [CNKeyDescriptor] = [CNContactImageDataKey as CNKeyDescriptor, CNContactVCardSerialization.descriptorForRequiredKeys()]
		var results: [ContactRecord] = []

		do {
			let contacts: [CNContact] = try self.store.unifiedContacts(matching: contactPredicate, keysToFetch: keysToFetch)

			for contact in contacts {
				results.append(ContactRecord(contactInstance: contact))
			}
		} catch let error {
			print(error)
		}

		completion(results)
	}

	public func getContactsInGroupAsCNContacts(groupId: String, completion: @escaping (_ contacts: [CNContact]) -> Void) {
		let contactPredicate: NSPredicate = CNContact.predicateForContactsInGroup(withIdentifier: groupId)
		let keysToFetch: [CNKeyDescriptor] = [CNContactImageDataKey as CNKeyDescriptor, CNContactVCardSerialization.descriptorForRequiredKeys()]
		var results: [CNContact] = []

		do {
			results = try self.store.unifiedContacts(matching: contactPredicate, keysToFetch: keysToFetch)
		} catch let error {
			print(error)
		}

		completion(results)
	}

	/// Method to search contacts setting "matching" param as the matchingName predicate
	///
	/// - Parameters:
	///   - matching: The string to filter contact names against
	///   - completion: Completion handler with matching contacts
	public func findContacts(matching: String, completion: @escaping (_ result: [CNContact]) -> Void) {
		let namePredicate: NSPredicate = CNContact.predicateForContacts(matchingName: matching)
		let identifierPredicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: [matching])
		var contacts: [CNContact] = []

		let keysToFetch: [CNKeyDescriptor] = [
			CNContactImageDataKey as CNKeyDescriptor,
			CNContactVCardSerialization.descriptorForRequiredKeys()
		]

		do {
			contacts = try store.unifiedContacts(matching: namePredicate, keysToFetch: keysToFetch)

			if contacts.count < 1 {
				contacts = try store.unifiedContacts(matching: identifierPredicate, keysToFetch: keysToFetch)
			}
		} catch let error as NSError {
			print(error.localizedDescription)
		}

		completion(contacts)
	}

	/// Method to retrieve all contacts with a property value matching "matching"
	///
	/// - Parameters:
	///   - matching: The string to filter contact properties against
	///   - completion: Completion handler with matching contacts
	public func findContactsDeep(matching: String, completion: @escaping (_ result: [CNContact]) -> Void) {
		var matchingContacts: [CNContact] = []

		self.findContacts(matching: "*") { (contacts) in
			for contact in contacts {
				let contactRecord = ContactRecord(contactInstance: contact)

				if contactRecord.somePropertyContains(search: matching) == true {
					matchingContacts.append(contact)
				}
			}

			completion(matchingContacts)
		}
	}

	/// Internal method to save a contact as a VCF
	///
	/// - Parameter contacts: Collection of contacts to export
	private func saveVcfs(contacts: [CNContact]) {
		for contact in contacts {
			if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
				let fileURL = dir.appendingPathComponent("\(contact.givenName) \(contact.familyName).vcf")
				do {
					try CNContactVCardSerialization
						.data(jpegPhotoContacts: [contact])
						.write(to: fileURL, options: [Data.WritingOptions.atomic])
				} catch let error {
					dump(error)
				}
			}
		}
	}

	/// Converts a collection CNContact instances into the desired output format
	///
	/// - Parameters:
	///   - filter: Match filter
	///   - output: Output directory (if format is "file")
	///   - format: Output type
	///   - result: CNContact collection
	/// - Returns: String representation of "result" collection
	private func formatSearchResults(filter: String, output: String?, format: String, result: [CNContact]) -> String {
		var outputString: String = ""

		/// Output data line by line directly to stdout
		if format == "text" {
			outputString += "Found \(result.count) contacts matching \"\(filter)\":\n\n"

			for contact in result {
				let foundContact = ContactRecord(contactInstance: contact)
				outputString += foundContact.contactToString() + "\n"
			}

			return outputString

		/// Write output to a VCF file in the passed directory (output parameter)
		} else if format == "file" {
			var dir: URL!

			if output == nil {
				dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
			} else {
				dir = URL.init(fileURLWithPath: output!)
			}

			for contact in result {
				var fileURL = dir.appendingPathComponent("\(contact.givenName) \(contact.familyName).vcf")

				if fileURL.lastPathComponent == " .vcf" {
					fileURL = dir.appendingPathComponent("\(contact.identifier).vcf")
				}

				do {
					try CNContactVCardSerialization
						.data(jpegPhotoContacts: [contact])
						.write(to: fileURL, options: [Data.WritingOptions.atomic])
				} catch let error {
					print(error)
				}
			}

			return "\(result.count) VCF file(s) written to \(dir.path)"

		/// Write output as VCF data to stdout (easily create an aggregate VCF by piping output)
		} else if format == "vcf" {
			for contact in result {
				do {
					let data = try CNContactVCardSerialization.data(jpegPhotoContacts: [contact])
					outputString += String(data: data, encoding: .utf8)! + "\n"
				} catch {}
			}

			return outputString

		/// Write output to CSV format, written to stdout
		} else {
			outputString += ContactRecord.CSVHeader() + "\n"

			for contact in result {
				let foundContact = ContactRecord(contactInstance: contact)
				outputString += foundContact.contactToCSV() + "\n"
			}

			return outputString
		}
	}
}

// MARK: - Extensions

/// VCF serialization
extension CNContactVCardSerialization {

	/// Retrieves vCard data for a given contact with the contact photo appended
	///
	/// - Parameters:
	///   - vcard: vcard data of target contact
	///   - photo: photo to be added to vCard
	/// - Returns: vCard data
	internal class func vcardDataAppendingPhoto(vcard: Data, photoAsBase64String photo: String) -> Data? {
		let vcardAsString = String(data: vcard, encoding: .utf8)
		let vcardPhoto = "PHOTO;TYPE=JPEG;ENCODING=BASE64:".appending(photo)
		let vcardPhotoThenEnd = vcardPhoto.appending("\nEND:VCARD")

		if let vcardPhotoAppended = vcardAsString?.replacingOccurrences(of: "END:VCARD", with: vcardPhotoThenEnd) {
			return vcardPhotoAppended.data(using: .utf8)
		}

		return nil
	}

	/// Base-64 encode a contact image when contact data is written to a file
	///
	/// - Parameter jpegPhotoContacts: Collection of CNContact instances to export
	/// - Returns: VCF data with or without the encoded contact image included
	/// - Throws: Error
	class func data(jpegPhotoContacts: [CNContact]) throws -> Data {
		var overallData = Data()

		for contact in jpegPhotoContacts {
			let data = try CNContactVCardSerialization.data(with: [contact])

			if contact.imageData != nil {
				if let base64imageString = contact.imageData?.base64EncodedString(),
					let updatedData = vcardDataAppendingPhoto(vcard: data, photoAsBase64String: base64imageString) {
					overallData.append(updatedData)
				}
			} else {
				overallData.append(data)
			}
		}
		return overallData
	}
}
