sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"asset/mgmt/assignments/test/integration/pages/AssignmentsList.gen",
	"asset/mgmt/assignments/test/integration/pages/AssignmentsObjectPage.gen"
], function (JourneyRunner, AssignmentsListGenerated, AssignmentsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('asset/mgmt/assignments') + '/test/flp.html#app-preview',
        pages: {
			onTheAssignmentsListGenerated: AssignmentsListGenerated,
			onTheAssignmentsObjectPageGenerated: AssignmentsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

