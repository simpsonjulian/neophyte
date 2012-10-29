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
import groovy.util.logging.Log

@Log
class IssueMigrator {
    final HTTPBuilder origin
    final RESTClient destination
    final String encodedCredentials

    IssueMigrator(repository, username, password) {
        origin = new HTTPBuilder('https://api.github.com/repos/neo4j/')
        destination = new RESTClient("https://api.github.com/repos/$username/$repository/")

        encodedCredentials = "$username:$password".getBytes().encodeBase64().toString()
    }

    def migrateIssues(repositories) {
        repositories.each { repository ->
            log.info("Migrating issues for $repository...")
            migrateLabels(repository)
            migrateOpenIssues(repository)
        }
    }

    def migrateLabels(repository) {
        try {
            origin.get(path: "$repository/labels", headers: [Authorization: "Basic $encodedCredentials"]) { resp, json ->
                json.findAll().each { label -> migrateLabel(label) }
            }
        } catch (HttpResponseException e) {
            // testing-utils doesn't have issues as it is a fork from DM's account
            if (e.statusCode != 410) throw e;
        }
    }

    def migrateLabel(label) {
        try {
            def response = destination.get(path: "labels/$label.name", headers: [Authorization: "Basic $encodedCredentials"])

            if (response.data.color != label.color) updateLabelColor(label.name, label.color)
        }
        catch (HttpResponseException e) {
            if (e.statusCode == 404) {
                createLabel(label)
            } else throw e
        }
    }

    private void createLabel(label) {
        destination.post(path: 'labels', body: label,
                requestContentType: ContentType.JSON,
                headers: [Authorization: "Basic $encodedCredentials"])
    }

    def updateLabelColor(name, color) {
        HttpPatch httpPatch = new HttpPatch("https://api.github.com/repos/lassewesth/repo/labels/$name")
        httpPatch.addHeader("Authorization", "Basic $encodedCredentials")
        httpPatch.addHeader("Content-Type", "application/json")
        httpPatch.setEntity(new StringEntity("{\"name\": \"$name\", \"color\": \"$color\"}"))

        HttpResponse response = destination.client.execute(httpPatch)

        response.getEntity().consumeContent()
    }

    def migrateOpenIssues(repository) {
        try {
            origin.get(path: "$repository/issues", headers: [Authorization: "Basic $encodedCredentials"]) { resp, json ->
                json.findAll().eachWithIndex { issue, index -> migrateOpenIssue(repository, issue)}
            }
        } catch (HttpResponseException e) {
            // testing-utils doesn't have issues as it is a fork from DM's account
            if (e.statusCode != 410) throw e;
        }
    }

    def migrateOpenIssue(repository, issue) {
        issue.milestone = null
        issue.assignee = null

        def response = destination.post(path: 'issues', body: issue, requestContentType: ContentType.JSON,
                headers: [Authorization: "Basic $encodedCredentials"])

        migrateComments(repository, issue, response.data.number)
    }

    private void migrateComments(repository, oldIssue, newIssueNumber) {
        // TODO: sort out mentions-as-posters somehow
        //lassewesthRepo.post(path: "issues/$newIssueNumber/comments", body: [body: "This issue was migrated from
        // $oldIssue.html_url".toString()], requestContentType: ContentType.JSON,
        // headers: [Authorization: "Basic bGFzc2V3ZXN0aDp1OTcxNzQ2"])

        origin.get(path: "$repository/issues/${oldIssue.number}/comments", headers: [Authorization: "Basic $encodedCredentials"]) { resp, json ->
            json.findAll().each { comment -> migrateComment(newIssueNumber, comment) }
        }
    }

    private void migrateComment(newIssueNumber, comment) {
        destination.post(path: "issues/$newIssueNumber/comments", body: comment,
                requestContentType: ContentType.JSON,
                headers: [Authorization: "Basic $encodedCredentials"])
    }
}
