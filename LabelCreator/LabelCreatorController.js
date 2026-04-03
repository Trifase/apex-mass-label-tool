/**
 * Created by Luca Bellanti on 2026-04-03.
 */

({
	doInit: function (component, event, helper) {
		helper.addEmptyRows(component, 10);
	},

	addRows: function (component, event, helper) {
		helper.addEmptyRows(component, 5);
	},

	clearAll: function (component, event, helper) {
		component.set('v.rows', []);
		component.set('v.successCount', 0);
		component.set('v.processedCount', 0);
		component.set('v.totalToProcess', 0);
		helper.addEmptyRows(component, 10);
	},

	removeRow: function (component, event, helper) {
		let idx = event.getSource().get('v.value');
		let rows = component.get('v.rows');
		rows.splice(idx, 1);
		component.set('v.rows', rows);
	},

	switchToCreate: function (component, event, helper) {
		component.set('v.mode', 'create');
	},

	switchToTranslate: function (component, event, helper) {
		component.set('v.mode', 'translate');
	},

	createLabels: function (component, event, helper) {
		let rows = component.get('v.rows');

		let validRows = [];
		for (let i = 0; i < rows.length; i++) {
			let row = rows[i];
			row.status = '';
			row.statusMessage = '';
			if (row.apiName && row.apiName.trim() && row.englishValue && row.englishValue.trim()) {
				validRows.push(i);
			}
		}
		component.set('v.rows', rows);

		if (validRows.length === 0) {
			helper.showToast('Warning', 'No valid rows found. API Name and English Value are required.', 'warning');
			return;
		}

		helper.startProcessing(component, validRows, 'create');
	},

	translateLabels: function (component, event, helper) {
		let lang = component.get('v.translationLanguage');
		if (!lang) {
			helper.showToast('Warning', 'Please select a translation language.', 'warning');
			return;
		}

		let rows = component.get('v.rows');

		let validRows = [];
		for (let i = 0; i < rows.length; i++) {
			let row = rows[i];
			row.status = '';
			row.statusMessage = '';
			if (row.apiName && row.apiName.trim() && row.translationValue && row.translationValue.trim()) {
				validRows.push(i);
			}
		}
		component.set('v.rows', rows);

		if (validRows.length === 0) {
			helper.showToast('Warning', 'No valid rows found. API Name and Translation are required.', 'warning');
			return;
		}

		helper.startProcessing(component, validRows, 'translate');
	},

	handleLanguageChange: function (component, event, helper) {
		helper.clearTranslationsOnRows(component);
	},

	handleFetchRowData: function (component, event, helper) {
		let rowIndex = event.getSource().get('v.value');
		helper.fetchLabelDataFromServer(component, rowIndex);
	}
})
