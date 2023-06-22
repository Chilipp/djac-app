#!/usr/bin/env node

/* jshint esversion: 8 */
/* jslint node:true */
/* global it:false */
/* global xit:false */
/* global describe:false */
/* global before:false */
/* global after:false */

'use strict';

require('chromedriver');

var execSync = require('child_process').execSync,
    expect = require('expect.js'),
    path = require('path'),
    { Builder, By, Key, until } = require('selenium-webdriver'),
    { Options } = require('selenium-webdriver/chrome');

if (!process.env.USERNAME || !process.env.PASSWORD) {
    console.log('USERNAME, PASSWORD env vars need to be set');
    process.exit(1);
}

describe('Application life cycle test', function () {
    this.timeout(0);

    var LOCATION = 'test';
    var EXEC_ARGS = { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' };
    var TIMEOUT = parseInt(process.env.TIMEOUT, 10) || 50000;

    var browser, app, shareLink;
    var username = process.env.USERNAME;
    var password = process.env.PASSWORD;
    var recipe = "Nuddles"
    var recipe2 = "Burger"

    before(function () {
        browser = new Builder().forBrowser('chrome').setChromeOptions(new Options().windowSize({ width: 1920, height: 1024 })).build();
    });

    after(function () {
        browser.quit();
    });

    function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }

    function getAppInfo() {
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION || a.location === LOCATION + '2'; })[0];
        expect(app).to.be.an('object');
    }

    async function login(username, password) {
        await browser.manage().deleteAllCookies();
        await browser.get(`https://${app.fqdn}/accounts/login/`);
        await browser.sleep(2000);

        if (await browser.findElements(By.xpath('//a[@class="dropdown-item" and contains(., "Log out")]')).then(found => !!found.length)) {
            await browser.get(`https://${app.fqdn}/accounts/logout/`);
            await browser.sleep(2000);
            await browser.get(`https://${app.fqdn}/accounts/login/`);
            await browser.sleep(2000);
        }

        /* native appp auth
        if (await browser.findElements(By.xpath('//input[@name="username"]')).then(found => !!found.length)) {
            await browser.findElement(By.xpath('//input[@name="login"]')).sendKeys(username);
            await browser.findElement(By.xpath('//input[@name="password"]')).sendKeys(password);
            await browser.sleep(2000);
            await browser.findElement(By.xpath('//button[@type="submit" and contains(., "Sign In")]')).click();
            await browser.sleep(2000);
        }
        */

        // OIDC
        if (await browser.findElements(By.xpath('//button[contains(text(), "Sign in using Cloudron")]')).then(found => !!found.length)) {
            await browser.findElement(By.xpath('//button[contains(text(), "Sign in using Cloudron")]')).click();
            await browser.sleep(2000);
            await browser.findElement(By.xpath('//button[contains(text(), "Continue")]')).click();
            await browser.sleep(2000);
        }

        if (await browser.findElements(By.xpath('//input[@name="username"]')).then(found => !!found.length)) {
            await browser.findElement(By.xpath('//input[@name="username"]')).sendKeys(username);
            await browser.findElement(By.xpath('//input[@name="password"]')).sendKeys(password);
            await browser.findElement(By.xpath('//button[@type="submit" and contains(text(), "Sign in")]')).click();
            await browser.sleep(2000);
        }

        if (await browser.findElements(By.xpath('//button[@type="submit" and contains(text(), "Authorize")]')).then(found => !!found.length)) {
            await browser.findElement(By.xpath('//button[@type="submit" and contains(text(), "Authorize")]')).click();
            await browser.sleep(2000);
        }

        if (await browser.findElements(By.xpath('//input[@value="Create Space"]')).then(found => !!found.length)) {
            await browser.findElement(By.xpath('//input[@value="Create Space"]')).click();
            browser.sleep(3000);
        }

        if (await browser.findElements(By.xpath('//p[@class="card-text" and contains(., "Create a new recipe directly in Tandoor.")]')).then(found => !!found.length) ||
            await browser.findElements(By.xpath('//div[contains(@class, "alert-success") and contains(., "Successfully signed in as ' + username + '")]')).then(found => !!found.length)) {
            return 1;
        }
        return 0;
//        await browser.wait(until.elementLocated(By.xpath('//p[@class="card-text" and contains(., "Create a new recipe directly in Tandoor.")]')), TIMEOUT);
//        await browser.wait(until.elementLocated(By.xpath('//div[contains(@class, "alert-success") and contains(., "Successfully signed in as ' + username + '")]')), TIMEOUT);
    }

    async function getMainPage() {
        await browser.get('https://' + app.fqdn + '/');
        await browser.sleep(5000);
        await browser.wait(until.elementLocated(By.xpath('//*[@id="collapse_advanced_search" or @aria-controls="collapse_advanced_search"]')), TIMEOUT);
    }

    async function createRecipe(recipename) {
        await browser.get(`https://${app.fqdn}/new/recipe/`);
        await browser.sleep(5000);

        await browser.findElement(By.id('id_name')).sendKeys(recipename);
        await browser.sleep(5000);
        await browser.findElement(By.xpath('//button[@type="submit" and contains(@class, "btn-success") and contains(., "Save")]')).click();
        await browser.sleep(5000);
        await browser.findElement(By.xpath('//button[@type="button" and contains(@class, "btn-info") and contains(., "Save")]')).click();
    }
    async function checkRecipe(recipename) {
        await browser.get('https://' + app.fqdn + '/search');
        await browser.sleep(2000);

        await browser.wait(until.elementLocated(By.xpath('//div[contains(@class, "card-body")]//a[contains(@class, "text-body") and contains(text(), "' + recipename + '")]')), TIMEOUT);
    }

    xit('build app', function () { execSync('cloudron build', EXEC_ARGS); });
    it('install app', async function () { execSync(`cloudron install --location ${LOCATION}`, EXEC_ARGS); });

    it('can get app information', getAppInfo);

    it('can login', login.bind(null, username, password));
    it('can get the main page', getMainPage);

    it('can create Recipe', createRecipe.bind(null, recipe));
    it('can create Recipe', createRecipe.bind(null, recipe2));
    it('check Recipe', checkRecipe.bind(null, recipe));
    it('check Recipe 2', checkRecipe.bind(null, recipe2));

    it('can restart app', async function () {
        execSync(`cloudron restart --app ${app.id}`, EXEC_ARGS);
        await sleep(20000);
    });

    it('check Recipe', checkRecipe.bind(null, recipe));
    it('check Recipe 2', checkRecipe.bind(null, recipe2));

    it('backup app', function () { execSync(`cloudron backup create --app ${app.id}`, EXEC_ARGS); });
    it('restore app', async function () {
        await browser.get('about:blank');
        const backups = JSON.parse(execSync(`cloudron backup list --raw --app ${app.id}`));
        execSync(`cloudron uninstall --app ${app.id}`, EXEC_ARGS);
        execSync(`cloudron install --location ${LOCATION}`, EXEC_ARGS);
        getAppInfo();
        execSync(`cloudron restore --backup ${backups[0].id} --app ${app.id}`, EXEC_ARGS);
        // wait when all services are up and running
        await sleep(20000);
    });

    it('can get app information', getAppInfo);

//    it('can login', login.bind(null, username, password));

    it('can get the main page', getMainPage);
    it('check Recipe', checkRecipe.bind(null, recipe));
    it('check Recipe 2', checkRecipe.bind(null, recipe2));

    it('move to different location', async function () {
        await browser.get('about:blank');
        execSync(`cloudron configure --location ${LOCATION}2 --app ${app.id}`, EXEC_ARGS);
        // wait when all services are up and running
        await sleep(20000);
    });
    it('can get app information', getAppInfo);
    it('can login', login.bind(null, username, password));
    it('can get the main page', getMainPage);
    it('check Recipe', checkRecipe.bind(null, recipe));
    it('check Recipe 2', checkRecipe.bind(null, recipe2));

    it('uninstall app', async function () {
        await browser.get('about:blank');
        execSync(`cloudron uninstall --app ${app.id}`, EXEC_ARGS);
    });

    // test update
/*
    it('can install app', async function () {
        execSync(`cloudron install --appstore-id dev.tandoor.cloudronapp --location ${LOCATION}`, EXEC_ARGS);
        // wait when all services are up and running
        await sleep(20000);
    });
    it('can get app information', getAppInfo);
    it('can login', login.bind(null, username, password));
    it('can get the main page', getMainPage);

    it('can create Recipe', createRecipe.bind(null, recipe));
    it('can create Recipe', createRecipe.bind(null, recipe2));
    it('check Recipe', checkRecipe.bind(null, recipe));
    it('check Recipe 2', checkRecipe.bind(null, recipe2));


    it('can update', function () { execSync(`cloudron update --app ${app.id}`, EXEC_ARGS); });

    it('check Recipe', checkRecipe.bind(null, recipe));
    it('check Recipe 2', checkRecipe.bind(null, recipe2));

    it('uninstall app', async function () {
        await browser.get('about:blank');
        execSync(`cloudron uninstall --app ${app.id}`, EXEC_ARGS);
    });
*/
});

