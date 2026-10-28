sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"asset/mgmt/myrequests/test/integration/pages/MyRequestsList.gen",
	"asset/mgmt/myrequests/test/integration/pages/MyRequestsObjectPage.gen"
], function (JourneyRunner, MyRequestsListGenerated, MyRequestsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('asset/mgmt/myrequests') + '/test/flp.html#app-preview',
        pages: {
			onTheMyRequestsListGenerated: MyRequestsListGenerated,
			onTheMyRequestsObjectPageGenerated: MyRequestsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

