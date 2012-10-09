package issuemigrator

/*
 * Copyright (C) 2012 Neo Technology
 * All rights reserved
 */

import groovyx.net.http.ContentType
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.HttpResponseException
import groovyx.net.http.RESTClient
import org.apache.http.HttpResponse
import org.apache.http.client.methods.HttpPatch
import org.apache.http.entity.StringEntity

class IssueMigrator {
    final HTTPBuilder neo4jCommunity
    final RESTClient lassewesthRepo
    final String encodedCredentials

    IssueMigrator(repository, username, password) {
        neo4jCommunity = new HTTPBuilder('https://api.github.com/repos/neo4j/community/')
        lassewesthRepo = new RESTClient("https://api.github.com/repos/$username/$repository/")

        encodedCredentials = "$username:$password".getBytes().encodeBase64().toString()
    }

    def migrateIssues() {
        migrateLabels()

        migrateOpenIssues()
    }

    def migrateLabels() {
        neo4jCommunity.get(path: 'labels') { resp, json ->
            json.findAll().each { label -> migrateLabel(label) }
        }
    }

    def migrateLabel(label) {
        try {
            def response = lassewesthRepo.get(path: "labels/$label.name")

            if (response.data.color != label.color) updateLabelColor(label.name, label.color)
        } catch (HttpResponseException e) {
            if (e.statusCode == 404) {
                createLabel(label)
            } else throw e
        }
    }

    private void createLabel(label) {
        lassewesthRepo.post(path: 'labels', body: label,
                requestContentType: ContentType.JSON,
                headers: [Authorization: "Basic $encodedCredentials"])
    }

    def updateLabelColor(name, color) {
        HttpPatch httpPatch = new HttpPatch("https://api.github.com/repos/lassewesth/repo/labels/$name")
        httpPatch.addHeader("Authorization", "Basic $encodedCredentials")
        httpPatch.addHeader("Content-Type", "application/json")
        httpPatch.setEntity(new StringEntity("{\"name\": \"$name\", \"color\": \"$color\"}"))

        HttpResponse response = lassewesthRepo.client.execute(httpPatch)

        response.getEntity().consumeContent()
    }

    def migrateOpenIssues() {
        neo4jCommunity.get(path: 'issues') { resp, json ->
            json.findAll().eachWithIndex { issue, index -> if (index < 30) migrateOpenIssue(issue)}
        }
    }

    def migrateOpenIssue(issue) {
        def response = lassewesthRepo.post(path: 'issues', body: issue, requestContentType: ContentType.JSON,
                headers: [Authorization: "Basic $encodedCredentials"])

        migrateComments(issue, response.data.number)
    }

    private void migrateComments(oldIssue, newIssueNumber) {
        // TODO: sort out mentions-as-posters somehow
        //lassewesthRepo.post(path: "issues/$newIssueNumber/comments", body: [body: "This issue was migrated from $oldIssue.html_url".toString()], requestContentType: ContentType.JSON, headers: [Authorization: "Basic bGFzc2V3ZXN0aDp1OTcxNzQ2"])

        neo4jCommunity.get(path: "issues/${oldIssue.number}/comments") { resp, json ->
            json.findAll().each { comment -> migrateComment(newIssueNumber, comment) }
        }
    }

    private void migrateComment(newIssueNumber, comment) {
        lassewesthRepo.post(path: "issues/$newIssueNumber/comments", body: comment,
                requestContentType: ContentType.JSON,
                headers: [Authorization: "Basic $encodedCredentials"])
    }
}
