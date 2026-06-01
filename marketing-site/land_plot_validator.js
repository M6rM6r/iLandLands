// JavaScript validator
class LandPlotValidator {
    static schema = {
        type: 'object',
        properties: {
            id: { type: 'string' },
            title: { type: 'string', minLength: 1, maxLength: 200 },
            description: { type: 'string', minLength: 1, maxLength: 2000 },
            price: { type: 'number', minimum: 0 },
            area: { type: 'number', minimum: 0 },
            country: { 
                type: 'string', 
                enum: ['saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait'] 
            },
            location: { type: 'string', minLength: 1, maxLength: 200 },
            imageUrls: { 
                type: 'array', 
                items: { type: 'string', format: 'uri' }, 
                minItems: 1 
            },
            isFeatured: { type: 'boolean' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
        },
        required: ['id', 'title', 'description', 'price', 'area', 'country', 'location', 'imageUrls', 'createdAt']
    };

    static validate(data) {
        const errors = [];

        // Required fields
        const required = this.schema.required;
        for (const field of required) {
            if (!(field in data)) {
                errors.push(`Missing required field: ${field}`);
            }
        }

        // Type validation
        if (typeof data.id !== 'string') errors.push('id must be a string');
        if (typeof data.title !== 'string' || data.title.length < 1 || data.title.length > 200) {
            errors.push('title must be a string between 1 and 200 characters');
        }
        if (typeof data.description !== 'string' || data.description.length < 1 || data.description.length > 2000) {
            errors.push('description must be a string between 1 and 2000 characters');
        }
        if (typeof data.price !== 'number' || data.price < 0) {
            errors.push('price must be a non-negative number');
        }
        if (typeof data.area !== 'number' || data.area < 0) {
            errors.push('area must be a non-negative number');
        }
        if (!this.schema.properties.country.enum.includes(data.country)) {
            errors.push('country must be one of: ' + this.schema.properties.country.enum.join(', '));
        }
        if (typeof data.location !== 'string' || data.location.length < 1 || data.location.length > 200) {
            errors.push('location must be a string between 1 and 200 characters');
        }
        if (!Array.isArray(data.imageUrls) || data.imageUrls.length < 1) {
            errors.push('imageUrls must be an array with at least 1 item');
        } else {
            for (const url of data.imageUrls) {
                if (typeof url !== 'string' || !url.match(/^https?:\/\//)) {
                    errors.push('imageUrls must contain valid HTTP/HTTPS URLs');
                }
            }
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LandPlotValidator;
}