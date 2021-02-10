import { ShowToastEvent } from "lightning/platformShowToastEvent";

/**
 * Creates an object from the array using the specified field as the key
 *
 * @template T
 * @param {Array.<T>} array
 * @param {string} field
 * @returns {Object.<string, T>}
 */
const keyByField = (array, field) => {
    const res = {};
    array.forEach((item) => {
        res[item[field]] = item;
    });
    return res;
};

/**
 * Groups the objects in the array by the specified key
 *
 * @template T
 * @param {Array.<T>} array
 * @param {string} field
 * @returns {Object.<string, Array.<T>>}
 */
const groupByField = (array, field) =>
    array.reduce(function (map, item) {
        const fieldValue = item[field];
        map[fieldValue] = map[fieldValue] || [];
        map[fieldValue].push(item);
        return map;
    }, Object.create(null));

const TOAST_VARIANT = {
    ERROR: "error",
    WARNING: "warning",
    SUCCESS: "success",
    INFO: "info"
};

/**
 * Displays an error toast showing the specified error message
 *
 * @param cmp The lwc component
 * @param message The error message
 */
const showErrorMessageToast = (cmp, message) => {
    cmp.dispatchEvent(
        new ShowToastEvent({
            title: "Error",
            message,
            variant: TOAST_VARIANT.ERROR
        })
    );
};

/**
 * Displays an error toast showing the error message contained in provided error object
 *
 * @param cmp The lwc component
 * @param error The error object
 */
const showErrorToast = (cmp, error) => {
    let errorMessages = [];
    if (error.body && error.body.pageErrors) {
        errorMessages = [...errorMessages, ...error.body.pageErrors.map((pe) => pe.message)];
    }

    if (error.body && error.body.fieldErrors) {
        errorMessages = [
            ...errorMessages,
            ...Object.values(error.body.fieldErrors)
                .flat()
                .map((ferror) => ferror.message)
        ];
    }

    if (error.body && error.body.message) {
        errorMessages.push(error.body.message);
    }

    showErrorMessageToast(cmp, errorMessages.join(" - "));
};

/**
 * Displays a success toast showing the provided message
 *
 * @param cmp The lwc component
 * @param message The message
 */
const showSuccessToast = (cmp, message) => {
    cmp.dispatchEvent(
        new ShowToastEvent({
            title: "Success",
            message: message,
            variant: TOAST_VARIANT.SUCCESS
        })
    );
};

/**
 * Displays an info toast showing the specified message
 *
 * @param cmp The lwc component
 * @param message The info message
 */
const showInfoToast = (cmp, message) => {
    cmp.dispatchEvent(
        new ShowToastEvent({
            title: "Info",
            message,
            variant: TOAST_VARIANT.INFO
        })
    );
};

export { keyByField, groupByField, showErrorToast, showErrorMessageToast, showSuccessToast, showInfoToast };
